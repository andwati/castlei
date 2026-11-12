#include <condition_variable>
#include <cstring>
#include <deque>
#include <mutex>
#include <sstream>
#include <thread>
#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <cctype>
#if defined(__linux__)
#include <sched.h>
#endif
#include "stockfish/src/engine.h"
#include "stockfish/src/attacks.h"
#include "stockfish/src/misc.h"
#include "stockfish/src/position.h"
#include "stockfish/src/uci.h"
#include "stockfish/src/ucioption.h"
using namespace Stockfish;
// Phones mix fast and slow cores. A search thread that lands on a slow core
// runs about 4x slower, so pin the engine to the fast ones (kernel cpu_capacity
// at least half of the best core). Threads created later inherit the mask.
// Returns how many fast cores there are, or 0 when it cannot tell.
static int pin_to_fast_cores() {
#if defined(__linux__)
 int cap[256]; int best = 0; int n = 0;
 for(; n < 256; n++) {
  char path[96]; std::snprintf(path, sizeof path, "/sys/devices/system/cpu/cpu%d/cpu_capacity", n);
  FILE* f = std::fopen(path, "r"); if(!f) break;
  int v = 0; if(std::fscanf(f, "%d", &v) != 1) v = 0; std::fclose(f);
  cap[n] = v; best = std::max(best, v);
 }
 if(n < 2 || best <= 0) return 0;
 cpu_set_t set; CPU_ZERO(&set); int fast = 0;
 for(int i = 0; i < n; i++) if(cap[i] * 2 >= best) { CPU_SET(i, &set); fast++; }
 if(fast == 0 || fast == n) return fast == n ? n : 0;
 if(sched_setaffinity(0, sizeof set, &set) != 0) return 0;
 return fast;
#else
 return 0;
#endif
}
struct Adapter {
 int maxThreads = 0;
 std::mutex mutex; std::condition_variable cv;
 std::deque<std::string> input, output;
 std::thread worker;
 void push(std::string s) {
  std::lock_guard lock(mutex);
  if(output.size() >= 4096) output.pop_front();
  output.push_back(std::move(s));
 }
 Adapter():worker([this]{run();}){}
 void run() noexcept {
  try {
   static std::once_flag init;
   std::call_once(init, []{Attacks::init(); Position::init();});
   maxThreads = pin_to_fast_cores();
   if(maxThreads <= 0) maxThreads = (int)std::max(1u, std::thread::hardware_concurrency());
   Engine engine;
   engine.set_on_update_no_moves([this](const auto& i){push("info depth 0 score " + UCIEngine::format_score(i.score));});
   engine.set_on_update_full([this](const auto& i){
    std::ostringstream s; s << "info depth " << i.depth << " multipv " << i.multiPV
    << " score " << UCIEngine::format_score(i.score) << " " << i.bound
    << " nodes " << i.nodes << " time " << i.timeMs << " pv " << i.pv; push(s.str());
   });
   engine.set_on_iter([](const auto&){});
   engine.set_on_start([]{});
   engine.set_on_bestmove([this](auto bm, auto){push("bestmove " + std::string(bm));});
   engine.set_on_verify_network([this](auto message){push("info string " + std::string(message));});
   while(true) {
    std::string cmd;
    {std::unique_lock lock(mutex); cv.wait(lock,[this]{return !input.empty();}); cmd=std::move(input.front()); input.pop_front();}
    if(maxThreads > 0) {
     // Never run more search threads than there are fast cores.
     const std::string key = "name Threads value "; auto at = cmd.find(key);
     if(cmd.rfind("setoption", 0) == 0 && at != std::string::npos)
      cmd = cmd.substr(0, at) + key + std::to_string(std::clamp(std::atoi(cmd.c_str() + at + key.size()), 1, maxThreads));
    }
    std::istringstream in(cmd); std::string token; in >> token;
    if(token=="quit"){engine.stop(); engine.wait_for_search_finished(); break;}
    if(token=="stop") engine.stop();
    else if(token=="uci"){std::ostringstream s; s << engine.get_options(); push("id name Stockfish 19 / Castlei"); push(s.str()); push("uciok");}
    else if(token=="isready") push("readyok");
    else if(token=="setoption"){engine.wait_for_search_finished(); engine.get_options().setoption(in);}
    else if(token=="ucinewgame"){engine.wait_for_search_finished(); engine.search_clear();}
    else if(token=="position") {
     engine.wait_for_search_finished();
     std::string fen, word; std::vector<std::string> moves; in >> word;
     if(word=="startpos") {fen="rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"; in >> word;}
     else {while(in >> word && word!="moves") fen += word + " ";}
     while(in >> word) moves.push_back(word);
     engine.set_position(fen,moves);
    } else if(token=="go") {
     Search::LimitsType limits; limits.startTime = now(); std::string t;
     while(in >> t) {
      if(t=="searchmoves"){while(in >> t) {std::transform(t.begin(), t.end(), t.begin(), [](unsigned char c){return std::tolower(c);}); limits.searchmoves.push_back(t);}; break;}
      else if(t=="wtime") in >> limits.time[WHITE]; else if(t=="btime") in >> limits.time[BLACK];
      else if(t=="winc") in >> limits.inc[WHITE]; else if(t=="binc") in >> limits.inc[BLACK];
      else if(t=="movestogo") in >> limits.movestogo; else if(t=="depth") in >> limits.depth;
      else if(t=="nodes") in >> limits.nodes; else if(t=="movetime") in >> limits.movetime;
      else if(t=="mate") in >> limits.mate; else if(t=="infinite") limits.infinite = 1;
      if(in.fail()) break;
     }
     engine.go(limits);
    }
   }
  } catch(const std::exception& e){push(std::string("error ")+e.what());} catch(...){push("error native engine failure");}
 }
 ~Adapter(){ {std::lock_guard lock(mutex);input.push_back("quit");} cv.notify_one(); if(worker.joinable())worker.join(); }
};
#define API extern "C" __attribute__((visibility("default"))) __attribute__((used))
API void* castlei_create(){try{return new Adapter;}catch(...){return nullptr;}}
API int castlei_send(void* handle,const char* command){if(!handle||!command)return -1; auto* a=(Adapter*)handle; {std::lock_guard lock(a->mutex); if(a->input.size()>256)return -2;a->input.emplace_back(command);}a->cv.notify_one();return 0;}
API int castlei_poll(void* handle,char* buffer,int capacity){if(!handle||capacity<2)return -1;auto* a=(Adapter*)handle;std::lock_guard lock(a->mutex);if(a->output.empty())return 0;auto& s=a->output.front();if((int)s.size()+1>capacity)return -2;std::memcpy(buffer,s.c_str(),s.size()+1);int n=s.size();a->output.pop_front();return n;}
API void castlei_dispose(void* handle){delete (Adapter*)handle;}
