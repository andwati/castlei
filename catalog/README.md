# Castlei puzzle catalog
Publish this directory as the root of a separate public GitHub Pages repository.
Build the app with `--dart-define=CASTLEI_CATALOG_URL=https://OWNER.github.io/REPOSITORY/catalog.json`.
The app only refreshes on request and verifies pack SHA-256 before transactional installation.
Content derives from the Lichess CC0 puzzle database. Never place private application backups here.
Regenerate with `dart run tool/build_packs.dart PATH_TO_DATASET.csv`.
