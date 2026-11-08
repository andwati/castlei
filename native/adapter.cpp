#include <condition_variable>
#include <cstring>
#include <deque>
#include <mutex>
#include <sstream>
#include <thread>
#include "stockfish/src/engine.h"
#include "stockfish/src/bitboard.h"
#include "stockfish/src/position.h"
#include "stockfish/src/uci.h"
#include "stockfish/src/ucioption.h"
using namespace Stockfish;
struct Adapter {
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
   std::call_once(init, []{Bitboards::init(); Position::init();});
   Engine engine;
   engine.set_on_update_no_moves([this](const auto& i){push("info depth 0 score " + UCIEngine::format_score(i.score));});
   engine.set_on_update_full([this](const auto& i){
    std::ostringstream s; s << "info depth " << i.depth << " multipv " << i.multiPV
    << " score " << UCIEngine::format_score(i.score) << " " << i.bound
    << " nodes " << i.nodes << " time " << i.timeMs << " pv " << i.pv; push(s.str());
   });
   engine.set_on_iter([](const auto&){});
   engine.set_on_bestmove([this](auto bm, auto){push("bestmove " + std::string(bm));});
   engine.set_on_verify_networks([this](auto message){push("info string " + std::string(message));});
   while(true) {
    std::string cmd;
    {std::unique_lock lock(mutex); cv.wait(lock,[this]{return !input.empty();}); cmd=std::move(input.front()); input.pop_front();}
    std::istringstream in(cmd); std::string token; in >> token;
    if(token=="quit"){engine.stop(); engine.wait_for_search_finished(); break;}
    if(token=="stop") engine.stop();
    else if(token=="uci"){std::ostringstream s; s << engine.get_options(); push("id name Stockfish 18 / Castlei"); push(s.str()); push("uciok");}
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
    } else if(token=="go") {auto limits=UCIEngine::parse_limits(in); engine.go(limits);}
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
