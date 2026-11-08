// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class Games extends Table with TableInfo<Games, Game> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Games(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _rootFenMeta = const VerificationMeta(
    'rootFen',
  );
  late final GeneratedColumn<String> rootFen = GeneratedColumn<String>(
    'root_fen',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _headersMeta = const VerificationMeta(
    'headers',
  );
  late final GeneratedColumn<String> headers = GeneratedColumn<String>(
    'headers',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'{}\'',
    defaultValue: const CustomExpression('\'{}\''),
  );
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
    'result',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'*\'',
    defaultValue: const CustomExpression('\'*\''),
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  late final GeneratedColumn<int> created = GeneratedColumn<int>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedMeta = const VerificationMeta(
    'updated',
  );
  late final GeneratedColumn<int> updated = GeneratedColumn<int>(
    'updated',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _favoriteMeta = const VerificationMeta(
    'favorite',
  );
  late final GeneratedColumn<int> favorite = GeneratedColumn<int>(
    'favorite',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _settingsMeta = const VerificationMeta(
    'settings',
  );
  late final GeneratedColumn<String> settings = GeneratedColumn<String>(
    'settings',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'{}\'',
    defaultValue: const CustomExpression('\'{}\''),
  );
  static const VerificationMeta _currentNodeMeta = const VerificationMeta(
    'currentNode',
  );
  late final GeneratedColumn<String> currentNode = GeneratedColumn<String>(
    'current_node',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _assistedMeta = const VerificationMeta(
    'assisted',
  );
  late final GeneratedColumn<int> assisted = GeneratedColumn<int>(
    'assisted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    source,
    rootFen,
    headers,
    result,
    created,
    updated,
    favorite,
    settings,
    currentNode,
    assisted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'games';
  @override
  VerificationContext validateIntegrity(
    Insertable<Game> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('root_fen')) {
      context.handle(
        _rootFenMeta,
        rootFen.isAcceptableOrUnknown(data['root_fen']!, _rootFenMeta),
      );
    } else if (isInserting) {
      context.missing(_rootFenMeta);
    }
    if (data.containsKey('headers')) {
      context.handle(
        _headersMeta,
        headers.isAcceptableOrUnknown(data['headers']!, _headersMeta),
      );
    }
    if (data.containsKey('result')) {
      context.handle(
        _resultMeta,
        result.isAcceptableOrUnknown(data['result']!, _resultMeta),
      );
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('updated')) {
      context.handle(
        _updatedMeta,
        updated.isAcceptableOrUnknown(data['updated']!, _updatedMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedMeta);
    }
    if (data.containsKey('favorite')) {
      context.handle(
        _favoriteMeta,
        favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta),
      );
    }
    if (data.containsKey('settings')) {
      context.handle(
        _settingsMeta,
        settings.isAcceptableOrUnknown(data['settings']!, _settingsMeta),
      );
    }
    if (data.containsKey('current_node')) {
      context.handle(
        _currentNodeMeta,
        currentNode.isAcceptableOrUnknown(
          data['current_node']!,
          _currentNodeMeta,
        ),
      );
    }
    if (data.containsKey('assisted')) {
      context.handle(
        _assistedMeta,
        assisted.isAcceptableOrUnknown(data['assisted']!, _assistedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Game map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Game(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      rootFen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root_fen'],
      )!,
      headers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}headers'],
      )!,
      result: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result'],
      )!,
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created'],
      )!,
      updated: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated'],
      )!,
      favorite: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}favorite'],
      )!,
      settings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settings'],
      )!,
      currentNode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_node'],
      ),
      assisted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}assisted'],
      )!,
    );
  }

  @override
  Games createAlias(String alias) {
    return Games(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Game extends DataClass implements Insertable<Game> {
  final String id;
  final String title;
  final String source;
  final String rootFen;
  final String headers;
  final String result;
  final int created;
  final int updated;
  final int favorite;
  final String settings;
  final String? currentNode;
  final int assisted;
  const Game({
    required this.id,
    required this.title,
    required this.source,
    required this.rootFen,
    required this.headers,
    required this.result,
    required this.created,
    required this.updated,
    required this.favorite,
    required this.settings,
    this.currentNode,
    required this.assisted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['source'] = Variable<String>(source);
    map['root_fen'] = Variable<String>(rootFen);
    map['headers'] = Variable<String>(headers);
    map['result'] = Variable<String>(result);
    map['created'] = Variable<int>(created);
    map['updated'] = Variable<int>(updated);
    map['favorite'] = Variable<int>(favorite);
    map['settings'] = Variable<String>(settings);
    if (!nullToAbsent || currentNode != null) {
      map['current_node'] = Variable<String>(currentNode);
    }
    map['assisted'] = Variable<int>(assisted);
    return map;
  }

  GamesCompanion toCompanion(bool nullToAbsent) {
    return GamesCompanion(
      id: Value(id),
      title: Value(title),
      source: Value(source),
      rootFen: Value(rootFen),
      headers: Value(headers),
      result: Value(result),
      created: Value(created),
      updated: Value(updated),
      favorite: Value(favorite),
      settings: Value(settings),
      currentNode: currentNode == null && nullToAbsent
          ? const Value.absent()
          : Value(currentNode),
      assisted: Value(assisted),
    );
  }

  factory Game.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Game(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      source: serializer.fromJson<String>(json['source']),
      rootFen: serializer.fromJson<String>(json['root_fen']),
      headers: serializer.fromJson<String>(json['headers']),
      result: serializer.fromJson<String>(json['result']),
      created: serializer.fromJson<int>(json['created']),
      updated: serializer.fromJson<int>(json['updated']),
      favorite: serializer.fromJson<int>(json['favorite']),
      settings: serializer.fromJson<String>(json['settings']),
      currentNode: serializer.fromJson<String?>(json['current_node']),
      assisted: serializer.fromJson<int>(json['assisted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'source': serializer.toJson<String>(source),
      'root_fen': serializer.toJson<String>(rootFen),
      'headers': serializer.toJson<String>(headers),
      'result': serializer.toJson<String>(result),
      'created': serializer.toJson<int>(created),
      'updated': serializer.toJson<int>(updated),
      'favorite': serializer.toJson<int>(favorite),
      'settings': serializer.toJson<String>(settings),
      'current_node': serializer.toJson<String?>(currentNode),
      'assisted': serializer.toJson<int>(assisted),
    };
  }

  Game copyWith({
    String? id,
    String? title,
    String? source,
    String? rootFen,
    String? headers,
    String? result,
    int? created,
    int? updated,
    int? favorite,
    String? settings,
    Value<String?> currentNode = const Value.absent(),
    int? assisted,
  }) => Game(
    id: id ?? this.id,
    title: title ?? this.title,
    source: source ?? this.source,
    rootFen: rootFen ?? this.rootFen,
    headers: headers ?? this.headers,
    result: result ?? this.result,
    created: created ?? this.created,
    updated: updated ?? this.updated,
    favorite: favorite ?? this.favorite,
    settings: settings ?? this.settings,
    currentNode: currentNode.present ? currentNode.value : this.currentNode,
    assisted: assisted ?? this.assisted,
  );
  Game copyWithCompanion(GamesCompanion data) {
    return Game(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      source: data.source.present ? data.source.value : this.source,
      rootFen: data.rootFen.present ? data.rootFen.value : this.rootFen,
      headers: data.headers.present ? data.headers.value : this.headers,
      result: data.result.present ? data.result.value : this.result,
      created: data.created.present ? data.created.value : this.created,
      updated: data.updated.present ? data.updated.value : this.updated,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      settings: data.settings.present ? data.settings.value : this.settings,
      currentNode: data.currentNode.present
          ? data.currentNode.value
          : this.currentNode,
      assisted: data.assisted.present ? data.assisted.value : this.assisted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Game(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('source: $source, ')
          ..write('rootFen: $rootFen, ')
          ..write('headers: $headers, ')
          ..write('result: $result, ')
          ..write('created: $created, ')
          ..write('updated: $updated, ')
          ..write('favorite: $favorite, ')
          ..write('settings: $settings, ')
          ..write('currentNode: $currentNode, ')
          ..write('assisted: $assisted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    source,
    rootFen,
    headers,
    result,
    created,
    updated,
    favorite,
    settings,
    currentNode,
    assisted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Game &&
          other.id == this.id &&
          other.title == this.title &&
          other.source == this.source &&
          other.rootFen == this.rootFen &&
          other.headers == this.headers &&
          other.result == this.result &&
          other.created == this.created &&
          other.updated == this.updated &&
          other.favorite == this.favorite &&
          other.settings == this.settings &&
          other.currentNode == this.currentNode &&
          other.assisted == this.assisted);
}

class GamesCompanion extends UpdateCompanion<Game> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> source;
  final Value<String> rootFen;
  final Value<String> headers;
  final Value<String> result;
  final Value<int> created;
  final Value<int> updated;
  final Value<int> favorite;
  final Value<String> settings;
  final Value<String?> currentNode;
  final Value<int> assisted;
  final Value<int> rowid;
  const GamesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.source = const Value.absent(),
    this.rootFen = const Value.absent(),
    this.headers = const Value.absent(),
    this.result = const Value.absent(),
    this.created = const Value.absent(),
    this.updated = const Value.absent(),
    this.favorite = const Value.absent(),
    this.settings = const Value.absent(),
    this.currentNode = const Value.absent(),
    this.assisted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GamesCompanion.insert({
    required String id,
    required String title,
    required String source,
    required String rootFen,
    this.headers = const Value.absent(),
    this.result = const Value.absent(),
    required int created,
    required int updated,
    this.favorite = const Value.absent(),
    this.settings = const Value.absent(),
    this.currentNode = const Value.absent(),
    this.assisted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       source = Value(source),
       rootFen = Value(rootFen),
       created = Value(created),
       updated = Value(updated);
  static Insertable<Game> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? source,
    Expression<String>? rootFen,
    Expression<String>? headers,
    Expression<String>? result,
    Expression<int>? created,
    Expression<int>? updated,
    Expression<int>? favorite,
    Expression<String>? settings,
    Expression<String>? currentNode,
    Expression<int>? assisted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (source != null) 'source': source,
      if (rootFen != null) 'root_fen': rootFen,
      if (headers != null) 'headers': headers,
      if (result != null) 'result': result,
      if (created != null) 'created': created,
      if (updated != null) 'updated': updated,
      if (favorite != null) 'favorite': favorite,
      if (settings != null) 'settings': settings,
      if (currentNode != null) 'current_node': currentNode,
      if (assisted != null) 'assisted': assisted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GamesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? source,
    Value<String>? rootFen,
    Value<String>? headers,
    Value<String>? result,
    Value<int>? created,
    Value<int>? updated,
    Value<int>? favorite,
    Value<String>? settings,
    Value<String?>? currentNode,
    Value<int>? assisted,
    Value<int>? rowid,
  }) {
    return GamesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      source: source ?? this.source,
      rootFen: rootFen ?? this.rootFen,
      headers: headers ?? this.headers,
      result: result ?? this.result,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      favorite: favorite ?? this.favorite,
      settings: settings ?? this.settings,
      currentNode: currentNode ?? this.currentNode,
      assisted: assisted ?? this.assisted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rootFen.present) {
      map['root_fen'] = Variable<String>(rootFen.value);
    }
    if (headers.present) {
      map['headers'] = Variable<String>(headers.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    if (created.present) {
      map['created'] = Variable<int>(created.value);
    }
    if (updated.present) {
      map['updated'] = Variable<int>(updated.value);
    }
    if (favorite.present) {
      map['favorite'] = Variable<int>(favorite.value);
    }
    if (settings.present) {
      map['settings'] = Variable<String>(settings.value);
    }
    if (currentNode.present) {
      map['current_node'] = Variable<String>(currentNode.value);
    }
    if (assisted.present) {
      map['assisted'] = Variable<int>(assisted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GamesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('source: $source, ')
          ..write('rootFen: $rootFen, ')
          ..write('headers: $headers, ')
          ..write('result: $result, ')
          ..write('created: $created, ')
          ..write('updated: $updated, ')
          ..write('favorite: $favorite, ')
          ..write('settings: $settings, ')
          ..write('currentNode: $currentNode, ')
          ..write('assisted: $assisted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Nodes extends Table with TableInfo<Nodes, Node> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Nodes(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES games(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES nodes(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _ordinalMeta = const VerificationMeta(
    'ordinal',
  );
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
    'ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _uciMeta = const VerificationMeta('uci');
  late final GeneratedColumn<String> uci = GeneratedColumn<String>(
    'uci',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sanMeta = const VerificationMeta('san');
  late final GeneratedColumn<String> san = GeneratedColumn<String>(
    'san',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _nagsMeta = const VerificationMeta('nags');
  late final GeneratedColumn<String> nags = GeneratedColumn<String>(
    'nags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'[]\'',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _annotationsMeta = const VerificationMeta(
    'annotations',
  );
  late final GeneratedColumn<String> annotations = GeneratedColumn<String>(
    'annotations',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'[]\'',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _clocksMeta = const VerificationMeta('clocks');
  late final GeneratedColumn<String> clocks = GeneratedColumn<String>(
    'clocks',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'{}\'',
    defaultValue: const CustomExpression('\'{}\''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameId,
    parentId,
    ordinal,
    uci,
    san,
    comment,
    nags,
    annotations,
    clocks,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Node> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('ordinal')) {
      context.handle(
        _ordinalMeta,
        ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta),
      );
    } else if (isInserting) {
      context.missing(_ordinalMeta);
    }
    if (data.containsKey('uci')) {
      context.handle(
        _uciMeta,
        uci.isAcceptableOrUnknown(data['uci']!, _uciMeta),
      );
    } else if (isInserting) {
      context.missing(_uciMeta);
    }
    if (data.containsKey('san')) {
      context.handle(
        _sanMeta,
        san.isAcceptableOrUnknown(data['san']!, _sanMeta),
      );
    } else if (isInserting) {
      context.missing(_sanMeta);
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('nags')) {
      context.handle(
        _nagsMeta,
        nags.isAcceptableOrUnknown(data['nags']!, _nagsMeta),
      );
    }
    if (data.containsKey('annotations')) {
      context.handle(
        _annotationsMeta,
        annotations.isAcceptableOrUnknown(
          data['annotations']!,
          _annotationsMeta,
        ),
      );
    }
    if (data.containsKey('clocks')) {
      context.handle(
        _clocksMeta,
        clocks.isAcceptableOrUnknown(data['clocks']!, _clocksMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Node map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Node(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      ordinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal'],
      )!,
      uci: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uci'],
      )!,
      san: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}san'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      )!,
      nags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nags'],
      )!,
      annotations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}annotations'],
      )!,
      clocks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clocks'],
      )!,
    );
  }

  @override
  Nodes createAlias(String alias) {
    return Nodes(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Node extends DataClass implements Insertable<Node> {
  final String id;
  final String gameId;
  final String? parentId;
  final int ordinal;
  final String uci;
  final String san;
  final String comment;
  final String nags;
  final String annotations;
  final String clocks;
  const Node({
    required this.id,
    required this.gameId,
    this.parentId,
    required this.ordinal,
    required this.uci,
    required this.san,
    required this.comment,
    required this.nags,
    required this.annotations,
    required this.clocks,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['game_id'] = Variable<String>(gameId);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['ordinal'] = Variable<int>(ordinal);
    map['uci'] = Variable<String>(uci);
    map['san'] = Variable<String>(san);
    map['comment'] = Variable<String>(comment);
    map['nags'] = Variable<String>(nags);
    map['annotations'] = Variable<String>(annotations);
    map['clocks'] = Variable<String>(clocks);
    return map;
  }

  NodesCompanion toCompanion(bool nullToAbsent) {
    return NodesCompanion(
      id: Value(id),
      gameId: Value(gameId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      ordinal: Value(ordinal),
      uci: Value(uci),
      san: Value(san),
      comment: Value(comment),
      nags: Value(nags),
      annotations: Value(annotations),
      clocks: Value(clocks),
    );
  }

  factory Node.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Node(
      id: serializer.fromJson<String>(json['id']),
      gameId: serializer.fromJson<String>(json['game_id']),
      parentId: serializer.fromJson<String?>(json['parent_id']),
      ordinal: serializer.fromJson<int>(json['ordinal']),
      uci: serializer.fromJson<String>(json['uci']),
      san: serializer.fromJson<String>(json['san']),
      comment: serializer.fromJson<String>(json['comment']),
      nags: serializer.fromJson<String>(json['nags']),
      annotations: serializer.fromJson<String>(json['annotations']),
      clocks: serializer.fromJson<String>(json['clocks']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'game_id': serializer.toJson<String>(gameId),
      'parent_id': serializer.toJson<String?>(parentId),
      'ordinal': serializer.toJson<int>(ordinal),
      'uci': serializer.toJson<String>(uci),
      'san': serializer.toJson<String>(san),
      'comment': serializer.toJson<String>(comment),
      'nags': serializer.toJson<String>(nags),
      'annotations': serializer.toJson<String>(annotations),
      'clocks': serializer.toJson<String>(clocks),
    };
  }

  Node copyWith({
    String? id,
    String? gameId,
    Value<String?> parentId = const Value.absent(),
    int? ordinal,
    String? uci,
    String? san,
    String? comment,
    String? nags,
    String? annotations,
    String? clocks,
  }) => Node(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    parentId: parentId.present ? parentId.value : this.parentId,
    ordinal: ordinal ?? this.ordinal,
    uci: uci ?? this.uci,
    san: san ?? this.san,
    comment: comment ?? this.comment,
    nags: nags ?? this.nags,
    annotations: annotations ?? this.annotations,
    clocks: clocks ?? this.clocks,
  );
  Node copyWithCompanion(NodesCompanion data) {
    return Node(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
      uci: data.uci.present ? data.uci.value : this.uci,
      san: data.san.present ? data.san.value : this.san,
      comment: data.comment.present ? data.comment.value : this.comment,
      nags: data.nags.present ? data.nags.value : this.nags,
      annotations: data.annotations.present
          ? data.annotations.value
          : this.annotations,
      clocks: data.clocks.present ? data.clocks.value : this.clocks,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Node(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('parentId: $parentId, ')
          ..write('ordinal: $ordinal, ')
          ..write('uci: $uci, ')
          ..write('san: $san, ')
          ..write('comment: $comment, ')
          ..write('nags: $nags, ')
          ..write('annotations: $annotations, ')
          ..write('clocks: $clocks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    gameId,
    parentId,
    ordinal,
    uci,
    san,
    comment,
    nags,
    annotations,
    clocks,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Node &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.parentId == this.parentId &&
          other.ordinal == this.ordinal &&
          other.uci == this.uci &&
          other.san == this.san &&
          other.comment == this.comment &&
          other.nags == this.nags &&
          other.annotations == this.annotations &&
          other.clocks == this.clocks);
}

class NodesCompanion extends UpdateCompanion<Node> {
  final Value<String> id;
  final Value<String> gameId;
  final Value<String?> parentId;
  final Value<int> ordinal;
  final Value<String> uci;
  final Value<String> san;
  final Value<String> comment;
  final Value<String> nags;
  final Value<String> annotations;
  final Value<String> clocks;
  final Value<int> rowid;
  const NodesCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.uci = const Value.absent(),
    this.san = const Value.absent(),
    this.comment = const Value.absent(),
    this.nags = const Value.absent(),
    this.annotations = const Value.absent(),
    this.clocks = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NodesCompanion.insert({
    required String id,
    required String gameId,
    this.parentId = const Value.absent(),
    required int ordinal,
    required String uci,
    required String san,
    this.comment = const Value.absent(),
    this.nags = const Value.absent(),
    this.annotations = const Value.absent(),
    this.clocks = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       gameId = Value(gameId),
       ordinal = Value(ordinal),
       uci = Value(uci),
       san = Value(san);
  static Insertable<Node> custom({
    Expression<String>? id,
    Expression<String>? gameId,
    Expression<String>? parentId,
    Expression<int>? ordinal,
    Expression<String>? uci,
    Expression<String>? san,
    Expression<String>? comment,
    Expression<String>? nags,
    Expression<String>? annotations,
    Expression<String>? clocks,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (parentId != null) 'parent_id': parentId,
      if (ordinal != null) 'ordinal': ordinal,
      if (uci != null) 'uci': uci,
      if (san != null) 'san': san,
      if (comment != null) 'comment': comment,
      if (nags != null) 'nags': nags,
      if (annotations != null) 'annotations': annotations,
      if (clocks != null) 'clocks': clocks,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NodesCompanion copyWith({
    Value<String>? id,
    Value<String>? gameId,
    Value<String?>? parentId,
    Value<int>? ordinal,
    Value<String>? uci,
    Value<String>? san,
    Value<String>? comment,
    Value<String>? nags,
    Value<String>? annotations,
    Value<String>? clocks,
    Value<int>? rowid,
  }) {
    return NodesCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      parentId: parentId ?? this.parentId,
      ordinal: ordinal ?? this.ordinal,
      uci: uci ?? this.uci,
      san: san ?? this.san,
      comment: comment ?? this.comment,
      nags: nags ?? this.nags,
      annotations: annotations ?? this.annotations,
      clocks: clocks ?? this.clocks,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (uci.present) {
      map['uci'] = Variable<String>(uci.value);
    }
    if (san.present) {
      map['san'] = Variable<String>(san.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (nags.present) {
      map['nags'] = Variable<String>(nags.value);
    }
    if (annotations.present) {
      map['annotations'] = Variable<String>(annotations.value);
    }
    if (clocks.present) {
      map['clocks'] = Variable<String>(clocks.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodesCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('parentId: $parentId, ')
          ..write('ordinal: $ordinal, ')
          ..write('uci: $uci, ')
          ..write('san: $san, ')
          ..write('comment: $comment, ')
          ..write('nags: $nags, ')
          ..write('annotations: $annotations, ')
          ..write('clocks: $clocks, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Analysis extends Table with TableInfo<Analysis, Analysi> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Analysis(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES games(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES nodes(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _configMeta = const VerificationMeta('config');
  late final GeneratedColumn<String> config = GeneratedColumn<String>(
    'config',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, gameId, nodeId, config, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'analysis';
  @override
  VerificationContext validateIntegrity(
    Insertable<Analysi> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('config')) {
      context.handle(
        _configMeta,
        config.isAcceptableOrUnknown(data['config']!, _configMeta),
      );
    } else if (isInserting) {
      context.missing(_configMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Analysi map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Analysi(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      config: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
    );
  }

  @override
  Analysis createAlias(String alias) {
    return Analysis(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Analysi extends DataClass implements Insertable<Analysi> {
  final String id;
  final String gameId;
  final String nodeId;
  final String config;
  final String data;
  const Analysi({
    required this.id,
    required this.gameId,
    required this.nodeId,
    required this.config,
    required this.data,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['game_id'] = Variable<String>(gameId);
    map['node_id'] = Variable<String>(nodeId);
    map['config'] = Variable<String>(config);
    map['data'] = Variable<String>(data);
    return map;
  }

  AnalysisCompanion toCompanion(bool nullToAbsent) {
    return AnalysisCompanion(
      id: Value(id),
      gameId: Value(gameId),
      nodeId: Value(nodeId),
      config: Value(config),
      data: Value(data),
    );
  }

  factory Analysi.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Analysi(
      id: serializer.fromJson<String>(json['id']),
      gameId: serializer.fromJson<String>(json['game_id']),
      nodeId: serializer.fromJson<String>(json['node_id']),
      config: serializer.fromJson<String>(json['config']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'game_id': serializer.toJson<String>(gameId),
      'node_id': serializer.toJson<String>(nodeId),
      'config': serializer.toJson<String>(config),
      'data': serializer.toJson<String>(data),
    };
  }

  Analysi copyWith({
    String? id,
    String? gameId,
    String? nodeId,
    String? config,
    String? data,
  }) => Analysi(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    nodeId: nodeId ?? this.nodeId,
    config: config ?? this.config,
    data: data ?? this.data,
  );
  Analysi copyWithCompanion(AnalysisCompanion data) {
    return Analysi(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      config: data.config.present ? data.config.value : this.config,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Analysi(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('nodeId: $nodeId, ')
          ..write('config: $config, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, gameId, nodeId, config, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Analysi &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.nodeId == this.nodeId &&
          other.config == this.config &&
          other.data == this.data);
}

class AnalysisCompanion extends UpdateCompanion<Analysi> {
  final Value<String> id;
  final Value<String> gameId;
  final Value<String> nodeId;
  final Value<String> config;
  final Value<String> data;
  final Value<int> rowid;
  const AnalysisCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.config = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnalysisCompanion.insert({
    required String id,
    required String gameId,
    required String nodeId,
    required String config,
    required String data,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       gameId = Value(gameId),
       nodeId = Value(nodeId),
       config = Value(config),
       data = Value(data);
  static Insertable<Analysi> custom({
    Expression<String>? id,
    Expression<String>? gameId,
    Expression<String>? nodeId,
    Expression<String>? config,
    Expression<String>? data,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (nodeId != null) 'node_id': nodeId,
      if (config != null) 'config': config,
      if (data != null) 'data': data,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnalysisCompanion copyWith({
    Value<String>? id,
    Value<String>? gameId,
    Value<String>? nodeId,
    Value<String>? config,
    Value<String>? data,
    Value<int>? rowid,
  }) {
    return AnalysisCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      nodeId: nodeId ?? this.nodeId,
      config: config ?? this.config,
      data: data ?? this.data,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (config.present) {
      map['config'] = Variable<String>(config.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnalysisCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('nodeId: $nodeId, ')
          ..write('config: $config, ')
          ..write('data: $data, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Repertoires extends Table with TableInfo<Repertoires, Repertoire> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Repertoires(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES games(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _sideMeta = const VerificationMeta('side');
  late final GeneratedColumn<String> side = GeneratedColumn<String>(
    'side',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, gameId, side];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'repertoires';
  @override
  VerificationContext validateIntegrity(
    Insertable<Repertoire> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('side')) {
      context.handle(
        _sideMeta,
        side.isAcceptableOrUnknown(data['side']!, _sideMeta),
      );
    } else if (isInserting) {
      context.missing(_sideMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Repertoire map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Repertoire(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      side: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}side'],
      )!,
    );
  }

  @override
  Repertoires createAlias(String alias) {
    return Repertoires(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Repertoire extends DataClass implements Insertable<Repertoire> {
  final String id;
  final String gameId;
  final String side;
  const Repertoire({
    required this.id,
    required this.gameId,
    required this.side,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['game_id'] = Variable<String>(gameId);
    map['side'] = Variable<String>(side);
    return map;
  }

  RepertoiresCompanion toCompanion(bool nullToAbsent) {
    return RepertoiresCompanion(
      id: Value(id),
      gameId: Value(gameId),
      side: Value(side),
    );
  }

  factory Repertoire.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Repertoire(
      id: serializer.fromJson<String>(json['id']),
      gameId: serializer.fromJson<String>(json['game_id']),
      side: serializer.fromJson<String>(json['side']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'game_id': serializer.toJson<String>(gameId),
      'side': serializer.toJson<String>(side),
    };
  }

  Repertoire copyWith({String? id, String? gameId, String? side}) => Repertoire(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    side: side ?? this.side,
  );
  Repertoire copyWithCompanion(RepertoiresCompanion data) {
    return Repertoire(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      side: data.side.present ? data.side.value : this.side,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Repertoire(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('side: $side')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, gameId, side);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Repertoire &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.side == this.side);
}

class RepertoiresCompanion extends UpdateCompanion<Repertoire> {
  final Value<String> id;
  final Value<String> gameId;
  final Value<String> side;
  final Value<int> rowid;
  const RepertoiresCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.side = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RepertoiresCompanion.insert({
    required String id,
    required String gameId,
    required String side,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       gameId = Value(gameId),
       side = Value(side);
  static Insertable<Repertoire> custom({
    Expression<String>? id,
    Expression<String>? gameId,
    Expression<String>? side,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (side != null) 'side': side,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RepertoiresCompanion copyWith({
    Value<String>? id,
    Value<String>? gameId,
    Value<String>? side,
    Value<int>? rowid,
  }) {
    return RepertoiresCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      side: side ?? this.side,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (side.present) {
      map['side'] = Variable<String>(side.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RepertoiresCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('side: $side, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Cards extends Table with TableInfo<Cards, Card> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Cards(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _repertoireIdMeta = const VerificationMeta(
    'repertoireId',
  );
  late final GeneratedColumn<String> repertoireId = GeneratedColumn<String>(
    'repertoire_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES repertoires(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _fenMeta = const VerificationMeta('fen');
  late final GeneratedColumn<String> fen = GeneratedColumn<String>(
    'fen',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _movesMeta = const VerificationMeta('moves');
  late final GeneratedColumn<String> moves = GeneratedColumn<String>(
    'moves',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  late final GeneratedColumn<int> stage = GeneratedColumn<int>(
    'stage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _dueMeta = const VerificationMeta('due');
  late final GeneratedColumn<int> due = GeneratedColumn<int>(
    'due',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    repertoireId,
    fen,
    moves,
    stage,
    due,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<Card> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('repertoire_id')) {
      context.handle(
        _repertoireIdMeta,
        repertoireId.isAcceptableOrUnknown(
          data['repertoire_id']!,
          _repertoireIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_repertoireIdMeta);
    }
    if (data.containsKey('fen')) {
      context.handle(
        _fenMeta,
        fen.isAcceptableOrUnknown(data['fen']!, _fenMeta),
      );
    } else if (isInserting) {
      context.missing(_fenMeta);
    }
    if (data.containsKey('moves')) {
      context.handle(
        _movesMeta,
        moves.isAcceptableOrUnknown(data['moves']!, _movesMeta),
      );
    } else if (isInserting) {
      context.missing(_movesMeta);
    }
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    }
    if (data.containsKey('due')) {
      context.handle(
        _dueMeta,
        due.isAcceptableOrUnknown(data['due']!, _dueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Card map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Card(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      repertoireId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repertoire_id'],
      )!,
      fen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fen'],
      )!,
      moves: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}moves'],
      )!,
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage'],
      )!,
      due: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due'],
      )!,
    );
  }

  @override
  Cards createAlias(String alias) {
    return Cards(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Card extends DataClass implements Insertable<Card> {
  final String id;
  final String repertoireId;
  final String fen;
  final String moves;
  final int stage;
  final int due;
  const Card({
    required this.id,
    required this.repertoireId,
    required this.fen,
    required this.moves,
    required this.stage,
    required this.due,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['repertoire_id'] = Variable<String>(repertoireId);
    map['fen'] = Variable<String>(fen);
    map['moves'] = Variable<String>(moves);
    map['stage'] = Variable<int>(stage);
    map['due'] = Variable<int>(due);
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      id: Value(id),
      repertoireId: Value(repertoireId),
      fen: Value(fen),
      moves: Value(moves),
      stage: Value(stage),
      due: Value(due),
    );
  }

  factory Card.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Card(
      id: serializer.fromJson<String>(json['id']),
      repertoireId: serializer.fromJson<String>(json['repertoire_id']),
      fen: serializer.fromJson<String>(json['fen']),
      moves: serializer.fromJson<String>(json['moves']),
      stage: serializer.fromJson<int>(json['stage']),
      due: serializer.fromJson<int>(json['due']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'repertoire_id': serializer.toJson<String>(repertoireId),
      'fen': serializer.toJson<String>(fen),
      'moves': serializer.toJson<String>(moves),
      'stage': serializer.toJson<int>(stage),
      'due': serializer.toJson<int>(due),
    };
  }

  Card copyWith({
    String? id,
    String? repertoireId,
    String? fen,
    String? moves,
    int? stage,
    int? due,
  }) => Card(
    id: id ?? this.id,
    repertoireId: repertoireId ?? this.repertoireId,
    fen: fen ?? this.fen,
    moves: moves ?? this.moves,
    stage: stage ?? this.stage,
    due: due ?? this.due,
  );
  Card copyWithCompanion(CardsCompanion data) {
    return Card(
      id: data.id.present ? data.id.value : this.id,
      repertoireId: data.repertoireId.present
          ? data.repertoireId.value
          : this.repertoireId,
      fen: data.fen.present ? data.fen.value : this.fen,
      moves: data.moves.present ? data.moves.value : this.moves,
      stage: data.stage.present ? data.stage.value : this.stage,
      due: data.due.present ? data.due.value : this.due,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Card(')
          ..write('id: $id, ')
          ..write('repertoireId: $repertoireId, ')
          ..write('fen: $fen, ')
          ..write('moves: $moves, ')
          ..write('stage: $stage, ')
          ..write('due: $due')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, repertoireId, fen, moves, stage, due);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Card &&
          other.id == this.id &&
          other.repertoireId == this.repertoireId &&
          other.fen == this.fen &&
          other.moves == this.moves &&
          other.stage == this.stage &&
          other.due == this.due);
}

class CardsCompanion extends UpdateCompanion<Card> {
  final Value<String> id;
  final Value<String> repertoireId;
  final Value<String> fen;
  final Value<String> moves;
  final Value<int> stage;
  final Value<int> due;
  final Value<int> rowid;
  const CardsCompanion({
    this.id = const Value.absent(),
    this.repertoireId = const Value.absent(),
    this.fen = const Value.absent(),
    this.moves = const Value.absent(),
    this.stage = const Value.absent(),
    this.due = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardsCompanion.insert({
    required String id,
    required String repertoireId,
    required String fen,
    required String moves,
    this.stage = const Value.absent(),
    this.due = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       repertoireId = Value(repertoireId),
       fen = Value(fen),
       moves = Value(moves);
  static Insertable<Card> custom({
    Expression<String>? id,
    Expression<String>? repertoireId,
    Expression<String>? fen,
    Expression<String>? moves,
    Expression<int>? stage,
    Expression<int>? due,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (repertoireId != null) 'repertoire_id': repertoireId,
      if (fen != null) 'fen': fen,
      if (moves != null) 'moves': moves,
      if (stage != null) 'stage': stage,
      if (due != null) 'due': due,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardsCompanion copyWith({
    Value<String>? id,
    Value<String>? repertoireId,
    Value<String>? fen,
    Value<String>? moves,
    Value<int>? stage,
    Value<int>? due,
    Value<int>? rowid,
  }) {
    return CardsCompanion(
      id: id ?? this.id,
      repertoireId: repertoireId ?? this.repertoireId,
      fen: fen ?? this.fen,
      moves: moves ?? this.moves,
      stage: stage ?? this.stage,
      due: due ?? this.due,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (repertoireId.present) {
      map['repertoire_id'] = Variable<String>(repertoireId.value);
    }
    if (fen.present) {
      map['fen'] = Variable<String>(fen.value);
    }
    if (moves.present) {
      map['moves'] = Variable<String>(moves.value);
    }
    if (stage.present) {
      map['stage'] = Variable<int>(stage.value);
    }
    if (due.present) {
      map['due'] = Variable<int>(due.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsCompanion(')
          ..write('id: $id, ')
          ..write('repertoireId: $repertoireId, ')
          ..write('fen: $fen, ')
          ..write('moves: $moves, ')
          ..write('stage: $stage, ')
          ..write('due: $due, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Puzzles extends Table with TableInfo<Puzzles, Puzzle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Puzzles(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _packMeta = const VerificationMeta('pack');
  late final GeneratedColumn<String> pack = GeneratedColumn<String>(
    'pack',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _fenMeta = const VerificationMeta('fen');
  late final GeneratedColumn<String> fen = GeneratedColumn<String>(
    'fen',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _movesMeta = const VerificationMeta('moves');
  late final GeneratedColumn<String> moves = GeneratedColumn<String>(
    'moves',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _themesMeta = const VerificationMeta('themes');
  late final GeneratedColumn<String> themes = GeneratedColumn<String>(
    'themes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, pack, fen, moves, rating, themes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'puzzles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Puzzle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pack')) {
      context.handle(
        _packMeta,
        pack.isAcceptableOrUnknown(data['pack']!, _packMeta),
      );
    } else if (isInserting) {
      context.missing(_packMeta);
    }
    if (data.containsKey('fen')) {
      context.handle(
        _fenMeta,
        fen.isAcceptableOrUnknown(data['fen']!, _fenMeta),
      );
    } else if (isInserting) {
      context.missing(_fenMeta);
    }
    if (data.containsKey('moves')) {
      context.handle(
        _movesMeta,
        moves.isAcceptableOrUnknown(data['moves']!, _movesMeta),
      );
    } else if (isInserting) {
      context.missing(_movesMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('themes')) {
      context.handle(
        _themesMeta,
        themes.isAcceptableOrUnknown(data['themes']!, _themesMeta),
      );
    } else if (isInserting) {
      context.missing(_themesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Puzzle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Puzzle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pack: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pack'],
      )!,
      fen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fen'],
      )!,
      moves: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}moves'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      themes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}themes'],
      )!,
    );
  }

  @override
  Puzzles createAlias(String alias) {
    return Puzzles(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Puzzle extends DataClass implements Insertable<Puzzle> {
  final String id;
  final String pack;
  final String fen;
  final String moves;
  final int rating;
  final String themes;
  const Puzzle({
    required this.id,
    required this.pack,
    required this.fen,
    required this.moves,
    required this.rating,
    required this.themes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pack'] = Variable<String>(pack);
    map['fen'] = Variable<String>(fen);
    map['moves'] = Variable<String>(moves);
    map['rating'] = Variable<int>(rating);
    map['themes'] = Variable<String>(themes);
    return map;
  }

  PuzzlesCompanion toCompanion(bool nullToAbsent) {
    return PuzzlesCompanion(
      id: Value(id),
      pack: Value(pack),
      fen: Value(fen),
      moves: Value(moves),
      rating: Value(rating),
      themes: Value(themes),
    );
  }

  factory Puzzle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Puzzle(
      id: serializer.fromJson<String>(json['id']),
      pack: serializer.fromJson<String>(json['pack']),
      fen: serializer.fromJson<String>(json['fen']),
      moves: serializer.fromJson<String>(json['moves']),
      rating: serializer.fromJson<int>(json['rating']),
      themes: serializer.fromJson<String>(json['themes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pack': serializer.toJson<String>(pack),
      'fen': serializer.toJson<String>(fen),
      'moves': serializer.toJson<String>(moves),
      'rating': serializer.toJson<int>(rating),
      'themes': serializer.toJson<String>(themes),
    };
  }

  Puzzle copyWith({
    String? id,
    String? pack,
    String? fen,
    String? moves,
    int? rating,
    String? themes,
  }) => Puzzle(
    id: id ?? this.id,
    pack: pack ?? this.pack,
    fen: fen ?? this.fen,
    moves: moves ?? this.moves,
    rating: rating ?? this.rating,
    themes: themes ?? this.themes,
  );
  Puzzle copyWithCompanion(PuzzlesCompanion data) {
    return Puzzle(
      id: data.id.present ? data.id.value : this.id,
      pack: data.pack.present ? data.pack.value : this.pack,
      fen: data.fen.present ? data.fen.value : this.fen,
      moves: data.moves.present ? data.moves.value : this.moves,
      rating: data.rating.present ? data.rating.value : this.rating,
      themes: data.themes.present ? data.themes.value : this.themes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Puzzle(')
          ..write('id: $id, ')
          ..write('pack: $pack, ')
          ..write('fen: $fen, ')
          ..write('moves: $moves, ')
          ..write('rating: $rating, ')
          ..write('themes: $themes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pack, fen, moves, rating, themes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Puzzle &&
          other.id == this.id &&
          other.pack == this.pack &&
          other.fen == this.fen &&
          other.moves == this.moves &&
          other.rating == this.rating &&
          other.themes == this.themes);
}

class PuzzlesCompanion extends UpdateCompanion<Puzzle> {
  final Value<String> id;
  final Value<String> pack;
  final Value<String> fen;
  final Value<String> moves;
  final Value<int> rating;
  final Value<String> themes;
  final Value<int> rowid;
  const PuzzlesCompanion({
    this.id = const Value.absent(),
    this.pack = const Value.absent(),
    this.fen = const Value.absent(),
    this.moves = const Value.absent(),
    this.rating = const Value.absent(),
    this.themes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PuzzlesCompanion.insert({
    required String id,
    required String pack,
    required String fen,
    required String moves,
    required int rating,
    required String themes,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pack = Value(pack),
       fen = Value(fen),
       moves = Value(moves),
       rating = Value(rating),
       themes = Value(themes);
  static Insertable<Puzzle> custom({
    Expression<String>? id,
    Expression<String>? pack,
    Expression<String>? fen,
    Expression<String>? moves,
    Expression<int>? rating,
    Expression<String>? themes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pack != null) 'pack': pack,
      if (fen != null) 'fen': fen,
      if (moves != null) 'moves': moves,
      if (rating != null) 'rating': rating,
      if (themes != null) 'themes': themes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PuzzlesCompanion copyWith({
    Value<String>? id,
    Value<String>? pack,
    Value<String>? fen,
    Value<String>? moves,
    Value<int>? rating,
    Value<String>? themes,
    Value<int>? rowid,
  }) {
    return PuzzlesCompanion(
      id: id ?? this.id,
      pack: pack ?? this.pack,
      fen: fen ?? this.fen,
      moves: moves ?? this.moves,
      rating: rating ?? this.rating,
      themes: themes ?? this.themes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pack.present) {
      map['pack'] = Variable<String>(pack.value);
    }
    if (fen.present) {
      map['fen'] = Variable<String>(fen.value);
    }
    if (moves.present) {
      map['moves'] = Variable<String>(moves.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (themes.present) {
      map['themes'] = Variable<String>(themes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PuzzlesCompanion(')
          ..write('id: $id, ')
          ..write('pack: $pack, ')
          ..write('fen: $fen, ')
          ..write('moves: $moves, ')
          ..write('rating: $rating, ')
          ..write('themes: $themes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Packs extends Table with TableInfo<Packs, Pack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Packs(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _manifestMeta = const VerificationMeta(
    'manifest',
  );
  late final GeneratedColumn<String> manifest = GeneratedColumn<String>(
    'manifest',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, manifest];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'packs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Pack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('manifest')) {
      context.handle(
        _manifestMeta,
        manifest.isAcceptableOrUnknown(data['manifest']!, _manifestMeta),
      );
    } else if (isInserting) {
      context.missing(_manifestMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Pack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pack(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      manifest: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manifest'],
      )!,
    );
  }

  @override
  Packs createAlias(String alias) {
    return Packs(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Pack extends DataClass implements Insertable<Pack> {
  final String id;
  final String manifest;
  const Pack({required this.id, required this.manifest});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['manifest'] = Variable<String>(manifest);
    return map;
  }

  PacksCompanion toCompanion(bool nullToAbsent) {
    return PacksCompanion(id: Value(id), manifest: Value(manifest));
  }

  factory Pack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pack(
      id: serializer.fromJson<String>(json['id']),
      manifest: serializer.fromJson<String>(json['manifest']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'manifest': serializer.toJson<String>(manifest),
    };
  }

  Pack copyWith({String? id, String? manifest}) =>
      Pack(id: id ?? this.id, manifest: manifest ?? this.manifest);
  Pack copyWithCompanion(PacksCompanion data) {
    return Pack(
      id: data.id.present ? data.id.value : this.id,
      manifest: data.manifest.present ? data.manifest.value : this.manifest,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pack(')
          ..write('id: $id, ')
          ..write('manifest: $manifest')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, manifest);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pack && other.id == this.id && other.manifest == this.manifest);
}

class PacksCompanion extends UpdateCompanion<Pack> {
  final Value<String> id;
  final Value<String> manifest;
  final Value<int> rowid;
  const PacksCompanion({
    this.id = const Value.absent(),
    this.manifest = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PacksCompanion.insert({
    required String id,
    required String manifest,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       manifest = Value(manifest);
  static Insertable<Pack> custom({
    Expression<String>? id,
    Expression<String>? manifest,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (manifest != null) 'manifest': manifest,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PacksCompanion copyWith({
    Value<String>? id,
    Value<String>? manifest,
    Value<int>? rowid,
  }) {
    return PacksCompanion(
      id: id ?? this.id,
      manifest: manifest ?? this.manifest,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (manifest.present) {
      map['manifest'] = Variable<String>(manifest.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PacksCompanion(')
          ..write('id: $id, ')
          ..write('manifest: $manifest, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Attempts extends Table with TableInfo<Attempts, Attempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Attempts(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  late final GeneratedColumn<String> target = GeneratedColumn<String>(
    'target',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  late final GeneratedColumn<int> created = GeneratedColumn<int>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _successMeta = const VerificationMeta(
    'success',
  );
  late final GeneratedColumn<int> success = GeneratedColumn<int>(
    'success',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _hintsMeta = const VerificationMeta('hints');
  late final GeneratedColumn<int> hints = GeneratedColumn<int>(
    'hints',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    target,
    created,
    success,
    hints,
    duration,
    metadata,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('target')) {
      context.handle(
        _targetMeta,
        target.isAcceptableOrUnknown(data['target']!, _targetMeta),
      );
    } else if (isInserting) {
      context.missing(_targetMeta);
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('success')) {
      context.handle(
        _successMeta,
        success.isAcceptableOrUnknown(data['success']!, _successMeta),
      );
    } else if (isInserting) {
      context.missing(_successMeta);
    }
    if (data.containsKey('hints')) {
      context.handle(
        _hintsMeta,
        hints.isAcceptableOrUnknown(data['hints']!, _hintsMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    } else if (isInserting) {
      context.missing(_metadataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target'],
      )!,
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created'],
      )!,
      success: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}success'],
      )!,
      hints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hints'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      )!,
    );
  }

  @override
  Attempts createAlias(String alias) {
    return Attempts(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Attempt extends DataClass implements Insertable<Attempt> {
  final String id;
  final String kind;
  final String target;
  final int created;
  final int success;
  final int hints;
  final int duration;
  final String metadata;
  const Attempt({
    required this.id,
    required this.kind,
    required this.target,
    required this.created,
    required this.success,
    required this.hints,
    required this.duration,
    required this.metadata,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['target'] = Variable<String>(target);
    map['created'] = Variable<int>(created);
    map['success'] = Variable<int>(success);
    map['hints'] = Variable<int>(hints);
    map['duration'] = Variable<int>(duration);
    map['metadata'] = Variable<String>(metadata);
    return map;
  }

  AttemptsCompanion toCompanion(bool nullToAbsent) {
    return AttemptsCompanion(
      id: Value(id),
      kind: Value(kind),
      target: Value(target),
      created: Value(created),
      success: Value(success),
      hints: Value(hints),
      duration: Value(duration),
      metadata: Value(metadata),
    );
  }

  factory Attempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attempt(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      target: serializer.fromJson<String>(json['target']),
      created: serializer.fromJson<int>(json['created']),
      success: serializer.fromJson<int>(json['success']),
      hints: serializer.fromJson<int>(json['hints']),
      duration: serializer.fromJson<int>(json['duration']),
      metadata: serializer.fromJson<String>(json['metadata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'target': serializer.toJson<String>(target),
      'created': serializer.toJson<int>(created),
      'success': serializer.toJson<int>(success),
      'hints': serializer.toJson<int>(hints),
      'duration': serializer.toJson<int>(duration),
      'metadata': serializer.toJson<String>(metadata),
    };
  }

  Attempt copyWith({
    String? id,
    String? kind,
    String? target,
    int? created,
    int? success,
    int? hints,
    int? duration,
    String? metadata,
  }) => Attempt(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    target: target ?? this.target,
    created: created ?? this.created,
    success: success ?? this.success,
    hints: hints ?? this.hints,
    duration: duration ?? this.duration,
    metadata: metadata ?? this.metadata,
  );
  Attempt copyWithCompanion(AttemptsCompanion data) {
    return Attempt(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      target: data.target.present ? data.target.value : this.target,
      created: data.created.present ? data.created.value : this.created,
      success: data.success.present ? data.success.value : this.success,
      hints: data.hints.present ? data.hints.value : this.hints,
      duration: data.duration.present ? data.duration.value : this.duration,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attempt(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('target: $target, ')
          ..write('created: $created, ')
          ..write('success: $success, ')
          ..write('hints: $hints, ')
          ..write('duration: $duration, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    target,
    created,
    success,
    hints,
    duration,
    metadata,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attempt &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.target == this.target &&
          other.created == this.created &&
          other.success == this.success &&
          other.hints == this.hints &&
          other.duration == this.duration &&
          other.metadata == this.metadata);
}

class AttemptsCompanion extends UpdateCompanion<Attempt> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> target;
  final Value<int> created;
  final Value<int> success;
  final Value<int> hints;
  final Value<int> duration;
  final Value<String> metadata;
  final Value<int> rowid;
  const AttemptsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.target = const Value.absent(),
    this.created = const Value.absent(),
    this.success = const Value.absent(),
    this.hints = const Value.absent(),
    this.duration = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttemptsCompanion.insert({
    required String id,
    required String kind,
    required String target,
    required int created,
    required int success,
    this.hints = const Value.absent(),
    this.duration = const Value.absent(),
    required String metadata,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       target = Value(target),
       created = Value(created),
       success = Value(success),
       metadata = Value(metadata);
  static Insertable<Attempt> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? target,
    Expression<int>? created,
    Expression<int>? success,
    Expression<int>? hints,
    Expression<int>? duration,
    Expression<String>? metadata,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (target != null) 'target': target,
      if (created != null) 'created': created,
      if (success != null) 'success': success,
      if (hints != null) 'hints': hints,
      if (duration != null) 'duration': duration,
      if (metadata != null) 'metadata': metadata,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttemptsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? target,
    Value<int>? created,
    Value<int>? success,
    Value<int>? hints,
    Value<int>? duration,
    Value<String>? metadata,
    Value<int>? rowid,
  }) {
    return AttemptsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      target: target ?? this.target,
      created: created ?? this.created,
      success: success ?? this.success,
      hints: hints ?? this.hints,
      duration: duration ?? this.duration,
      metadata: metadata ?? this.metadata,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (target.present) {
      map['target'] = Variable<String>(target.value);
    }
    if (created.present) {
      map['created'] = Variable<int>(created.value);
    }
    if (success.present) {
      map['success'] = Variable<int>(success.value);
    }
    if (hints.present) {
      map['hints'] = Variable<int>(hints.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttemptsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('target: $target, ')
          ..write('created: $created, ')
          ..write('success: $success, ')
          ..write('hints: $hints, ')
          ..write('duration: $duration, ')
          ..write('metadata: $metadata, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Preferences extends Table with TableInfo<Preferences, Preference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Preferences(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Preference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Preference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Preference(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  Preferences createAlias(String alias) {
    return Preferences(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Preference extends DataClass implements Insertable<Preference> {
  final String key;
  final String value;
  const Preference({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(key: Value(key), value: Value(value));
  }

  factory Preference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Preference(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Preference copyWith({String? key, String? value}) =>
      Preference(key: key ?? this.key, value: value ?? this.value);
  Preference copyWithCompanion(PreferencesCompanion data) {
    return Preference(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Preference(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Preference &&
          other.key == this.key &&
          other.value == this.value);
}

class PreferencesCompanion extends UpdateCompanion<Preference> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferencesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Preference> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PreferencesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final Games games = Games(this);
  late final Nodes nodes = Nodes(this);
  late final Index nodesGame = Index(
    'nodes_game',
    'CREATE INDEX nodes_game ON nodes (game_id, parent_id, ordinal)',
  );
  late final Analysis analysis = Analysis(this);
  late final Repertoires repertoires = Repertoires(this);
  late final Cards cards = Cards(this);
  late final Puzzles puzzles = Puzzles(this);
  late final Packs packs = Packs(this);
  late final Attempts attempts = Attempts(this);
  late final Index attemptsTime = Index(
    'attempts_time',
    'CREATE INDEX attempts_time ON attempts (created, kind)',
  );
  late final Preferences preferences = Preferences(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    games,
    nodes,
    nodesGame,
    analysis,
    repertoires,
    cards,
    puzzles,
    packs,
    attempts,
    attemptsTime,
    preferences,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'games',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('nodes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'nodes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('nodes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'games',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('analysis', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'nodes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('analysis', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'games',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('repertoires', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'repertoires',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cards', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $GamesCreateCompanionBuilder = GamesCompanion Function({
  required String id,
  required String title,
  required String source,
  required String rootFen,
  Value<String> headers,
  Value<String> result,
  required int created,
  required int updated,
  Value<int> favorite,
  Value<String> settings,
  Value<String?> currentNode,
  Value<int> assisted,
  Value<int> rowid,
});
typedef $GamesUpdateCompanionBuilder = GamesCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> source,
  Value<String> rootFen,
  Value<String> headers,
  Value<String> result,
  Value<int> created,
  Value<int> updated,
  Value<int> favorite,
  Value<String> settings,
  Value<String?> currentNode,
  Value<int> assisted,
  Value<int> rowid,
});

final class $GamesReferences
    extends BaseReferences<_$AppDatabase, Games, Game> {
  $GamesReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<Nodes, List<Node>> _nodesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.nodes,
    aliasName: 'games__id__nodes__game_id',
  );

  $NodesProcessedTableManager get nodesRefs {
    final manager = $NodesTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_nodesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Analysis, List<Analysi>> _analysisRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.analysis,
    aliasName: 'games__id__analysis__game_id',
  );

  $AnalysisProcessedTableManager get analysisRefs {
    final manager = $AnalysisTableManager(
      $_db,
      $_db.analysis,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_analysisRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Repertoires, List<Repertoire>>
  _repertoiresRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.repertoires,
    aliasName: 'games__id__repertoires__game_id',
  );

  $RepertoiresProcessedTableManager get repertoiresRefs {
    final manager = $RepertoiresTableManager(
      $_db,
      $_db.repertoires,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_repertoiresRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $GamesFilterComposer extends Composer<_$AppDatabase, Games> {
  $GamesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rootFen => $composableBuilder(
    column: $table.rootFen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headers => $composableBuilder(
    column: $table.headers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settings => $composableBuilder(
    column: $table.settings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentNode => $composableBuilder(
    column: $table.currentNode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get assisted => $composableBuilder(
    column: $table.assisted,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> nodesRefs(
    Expression<bool> Function($NodesFilterComposer f) f,
  ) {
    final $NodesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $NodesFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> analysisRefs(
    Expression<bool> Function($AnalysisFilterComposer f) f,
  ) {
    final $AnalysisFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.analysis,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AnalysisFilterComposer(
            $db: $db,
            $table: $db.analysis,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> repertoiresRefs(
    Expression<bool> Function($RepertoiresFilterComposer f) f,
  ) {
    final $RepertoiresFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.repertoires,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RepertoiresFilterComposer(
            $db: $db,
            $table: $db.repertoires,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $GamesOrderingComposer extends Composer<_$AppDatabase, Games> {
  $GamesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rootFen => $composableBuilder(
    column: $table.rootFen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headers => $composableBuilder(
    column: $table.headers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settings => $composableBuilder(
    column: $table.settings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentNode => $composableBuilder(
    column: $table.currentNode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get assisted => $composableBuilder(
    column: $table.assisted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $GamesAnnotationComposer extends Composer<_$AppDatabase, Games> {
  $GamesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get rootFen =>
      $composableBuilder(column: $table.rootFen, builder: (column) => column);

  GeneratedColumn<String> get headers =>
      $composableBuilder(column: $table.headers, builder: (column) => column);

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<int> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<int> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => column);

  GeneratedColumn<int> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<String> get settings =>
      $composableBuilder(column: $table.settings, builder: (column) => column);

  GeneratedColumn<String> get currentNode => $composableBuilder(
    column: $table.currentNode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get assisted =>
      $composableBuilder(column: $table.assisted, builder: (column) => column);

  Expression<T> nodesRefs<T extends Object>(
    Expression<T> Function($NodesAnnotationComposer a) f,
  ) {
    final $NodesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $NodesAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> analysisRefs<T extends Object>(
    Expression<T> Function($AnalysisAnnotationComposer a) f,
  ) {
    final $AnalysisAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.analysis,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AnalysisAnnotationComposer(
            $db: $db,
            $table: $db.analysis,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> repertoiresRefs<T extends Object>(
    Expression<T> Function($RepertoiresAnnotationComposer a) f,
  ) {
    final $RepertoiresAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.repertoires,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RepertoiresAnnotationComposer(
            $db: $db,
            $table: $db.repertoires,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $GamesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Games,
          Game,
          $GamesFilterComposer,
          $GamesOrderingComposer,
          $GamesAnnotationComposer,
          $GamesCreateCompanionBuilder,
          $GamesUpdateCompanionBuilder,
          (Game, $GamesReferences),
          Game,
          PrefetchHooks Function({
            bool nodesRefs,
            bool analysisRefs,
            bool repertoiresRefs,
          })
        > {
  $GamesTableManager(_$AppDatabase db, Games table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $GamesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $GamesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $GamesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> rootFen = const Value.absent(),
                Value<String> headers = const Value.absent(),
                Value<String> result = const Value.absent(),
                Value<int> created = const Value.absent(),
                Value<int> updated = const Value.absent(),
                Value<int> favorite = const Value.absent(),
                Value<String> settings = const Value.absent(),
                Value<String?> currentNode = const Value.absent(),
                Value<int> assisted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GamesCompanion(
                id: id,
                title: title,
                source: source,
                rootFen: rootFen,
                headers: headers,
                result: result,
                created: created,
                updated: updated,
                favorite: favorite,
                settings: settings,
                currentNode: currentNode,
                assisted: assisted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String source,
                required String rootFen,
                Value<String> headers = const Value.absent(),
                Value<String> result = const Value.absent(),
                required int created,
                required int updated,
                Value<int> favorite = const Value.absent(),
                Value<String> settings = const Value.absent(),
                Value<String?> currentNode = const Value.absent(),
                Value<int> assisted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GamesCompanion.insert(
                id: id,
                title: title,
                source: source,
                rootFen: rootFen,
                headers: headers,
                result: result,
                created: created,
                updated: updated,
                favorite: favorite,
                settings: settings,
                currentNode: currentNode,
                assisted: assisted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Games, Game>(table),
                  $GamesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                nodesRefs = false,
                analysisRefs = false,
                repertoiresRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (nodesRefs) db.nodes,
                    if (analysisRefs) db.analysis,
                    if (repertoiresRefs) db.repertoires,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (nodesRefs)
                        await $_getPrefetchedDataByColumns<
                          Game,
                          Games,
                          Node,
                          Nodes
                        >(
                          currentTable: table,
                          referencedTable: $GamesReferences._nodesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $GamesReferences(db, table, p0).nodesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'game_id',
                          typedResults: items,
                        ),
                      if (analysisRefs)
                        await $_getPrefetchedDataByColumns<
                          Game,
                          Games,
                          Analysi,
                          Analysis
                        >(
                          currentTable: table,
                          referencedTable: $GamesReferences._analysisRefsTable(
                            db,
                          ),
                          managerFromTypedResult: (p0) =>
                              $GamesReferences(db, table, p0).analysisRefs,
                          currentColumn: 'id',
                          referencedColumn: 'game_id',
                          typedResults: items,
                        ),
                      if (repertoiresRefs)
                        await $_getPrefetchedDataByColumns<
                          Game,
                          Games,
                          Repertoire,
                          Repertoires
                        >(
                          currentTable: table,
                          referencedTable: $GamesReferences
                              ._repertoiresRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $GamesReferences(db, table, p0).repertoiresRefs,
                          currentColumn: 'id',
                          referencedColumn: 'game_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $GamesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Games,
      Game,
      $GamesFilterComposer,
      $GamesOrderingComposer,
      $GamesAnnotationComposer,
      $GamesCreateCompanionBuilder,
      $GamesUpdateCompanionBuilder,
      (Game, $GamesReferences),
      Game,
      PrefetchHooks Function({
        bool nodesRefs,
        bool analysisRefs,
        bool repertoiresRefs,
      })
    >;
typedef $NodesCreateCompanionBuilder = NodesCompanion Function({
  required String id,
  required String gameId,
  Value<String?> parentId,
  required int ordinal,
  required String uci,
  required String san,
  Value<String> comment,
  Value<String> nags,
  Value<String> annotations,
  Value<String> clocks,
  Value<int> rowid,
});
typedef $NodesUpdateCompanionBuilder = NodesCompanion Function({
  Value<String> id,
  Value<String> gameId,
  Value<String?> parentId,
  Value<int> ordinal,
  Value<String> uci,
  Value<String> san,
  Value<String> comment,
  Value<String> nags,
  Value<String> annotations,
  Value<String> clocks,
  Value<int> rowid,
});

final class $NodesReferences
    extends BaseReferences<_$AppDatabase, Nodes, Node> {
  $NodesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Games _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('nodes__game_id__games__id');

  $GamesProcessedTableManager get gameId {
    final $_column = $_itemColumn<String>('game_id')!;

    final manager = $GamesTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Nodes _parentIdTable(_$AppDatabase db) =>
      db.nodes.createAlias('nodes__parent_id__nodes__id');

  $NodesProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $NodesTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<Analysis, List<Analysi>> _analysisRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.analysis,
    aliasName: 'nodes__id__analysis__node_id',
  );

  $AnalysisProcessedTableManager get analysisRefs {
    final manager = $AnalysisTableManager(
      $_db,
      $_db.analysis,
    ).filter((f) => f.nodeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_analysisRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $NodesFilterComposer extends Composer<_$AppDatabase, Nodes> {
  $NodesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uci => $composableBuilder(
    column: $table.uci,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get san => $composableBuilder(
    column: $table.san,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nags => $composableBuilder(
    column: $table.nags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get annotations => $composableBuilder(
    column: $table.annotations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clocks => $composableBuilder(
    column: $table.clocks,
    builder: (column) => ColumnFilters(column),
  );

  $GamesFilterComposer get gameId {
    final $GamesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $GamesFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $NodesFilterComposer get parentId {
    final $NodesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $NodesFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> analysisRefs(
    Expression<bool> Function($AnalysisFilterComposer f) f,
  ) {
    final $AnalysisFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.analysis,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AnalysisFilterComposer(
            $db: $db,
            $table: $db.analysis,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $NodesOrderingComposer extends Composer<_$AppDatabase, Nodes> {
  $NodesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uci => $composableBuilder(
    column: $table.uci,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get san => $composableBuilder(
    column: $table.san,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nags => $composableBuilder(
    column: $table.nags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get annotations => $composableBuilder(
    column: $table.annotations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clocks => $composableBuilder(
    column: $table.clocks,
    builder: (column) => ColumnOrderings(column),
  );

  $GamesOrderingComposer get gameId {
    final $GamesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $GamesOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $NodesOrderingComposer get parentId {
    final $NodesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $NodesOrderingComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $NodesAnnotationComposer extends Composer<_$AppDatabase, Nodes> {
  $NodesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ordinal =>
      $composableBuilder(column: $table.ordinal, builder: (column) => column);

  GeneratedColumn<String> get uci =>
      $composableBuilder(column: $table.uci, builder: (column) => column);

  GeneratedColumn<String> get san =>
      $composableBuilder(column: $table.san, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<String> get nags =>
      $composableBuilder(column: $table.nags, builder: (column) => column);

  GeneratedColumn<String> get annotations => $composableBuilder(
    column: $table.annotations,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clocks =>
      $composableBuilder(column: $table.clocks, builder: (column) => column);

  $GamesAnnotationComposer get gameId {
    final $GamesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $GamesAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $NodesAnnotationComposer get parentId {
    final $NodesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $NodesAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> analysisRefs<T extends Object>(
    Expression<T> Function($AnalysisAnnotationComposer a) f,
  ) {
    final $AnalysisAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.analysis,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AnalysisAnnotationComposer(
            $db: $db,
            $table: $db.analysis,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $NodesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Nodes,
          Node,
          $NodesFilterComposer,
          $NodesOrderingComposer,
          $NodesAnnotationComposer,
          $NodesCreateCompanionBuilder,
          $NodesUpdateCompanionBuilder,
          (Node, $NodesReferences),
          Node,
          PrefetchHooks Function({
            bool gameId,
            bool parentId,
            bool analysisRefs,
          })
        > {
  $NodesTableManager(_$AppDatabase db, Nodes table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $NodesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $NodesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $NodesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> gameId = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> ordinal = const Value.absent(),
                Value<String> uci = const Value.absent(),
                Value<String> san = const Value.absent(),
                Value<String> comment = const Value.absent(),
                Value<String> nags = const Value.absent(),
                Value<String> annotations = const Value.absent(),
                Value<String> clocks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodesCompanion(
                id: id,
                gameId: gameId,
                parentId: parentId,
                ordinal: ordinal,
                uci: uci,
                san: san,
                comment: comment,
                nags: nags,
                annotations: annotations,
                clocks: clocks,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String gameId,
                Value<String?> parentId = const Value.absent(),
                required int ordinal,
                required String uci,
                required String san,
                Value<String> comment = const Value.absent(),
                Value<String> nags = const Value.absent(),
                Value<String> annotations = const Value.absent(),
                Value<String> clocks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodesCompanion.insert(
                id: id,
                gameId: gameId,
                parentId: parentId,
                ordinal: ordinal,
                uci: uci,
                san: san,
                comment: comment,
                nags: nags,
                annotations: annotations,
                clocks: clocks,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Nodes, Node>(table),
                  $NodesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({gameId = false, parentId = false, analysisRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (analysisRefs) db.analysis],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (gameId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.gameId,
                            referencedTable: $NodesReferences._gameIdTable(db),
                            referencedColumn: $NodesReferences
                                ._gameIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (parentId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.parentId,
                            referencedTable: $NodesReferences._parentIdTable(
                              db,
                            ),
                            referencedColumn: $NodesReferences
                                ._parentIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (analysisRefs)
                        await $_getPrefetchedDataByColumns<
                          Node,
                          Nodes,
                          Analysi,
                          Analysis
                        >(
                          currentTable: table,
                          referencedTable: $NodesReferences._analysisRefsTable(
                            db,
                          ),
                          managerFromTypedResult: (p0) =>
                              $NodesReferences(db, table, p0).analysisRefs,
                          currentColumn: 'id',
                          referencedColumn: 'node_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $NodesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Nodes,
      Node,
      $NodesFilterComposer,
      $NodesOrderingComposer,
      $NodesAnnotationComposer,
      $NodesCreateCompanionBuilder,
      $NodesUpdateCompanionBuilder,
      (Node, $NodesReferences),
      Node,
      PrefetchHooks Function({bool gameId, bool parentId, bool analysisRefs})
    >;
typedef $AnalysisCreateCompanionBuilder = AnalysisCompanion Function({
  required String id,
  required String gameId,
  required String nodeId,
  required String config,
  required String data,
  Value<int> rowid,
});
typedef $AnalysisUpdateCompanionBuilder = AnalysisCompanion Function({
  Value<String> id,
  Value<String> gameId,
  Value<String> nodeId,
  Value<String> config,
  Value<String> data,
  Value<int> rowid,
});

final class $AnalysisReferences
    extends BaseReferences<_$AppDatabase, Analysis, Analysi> {
  $AnalysisReferences(super.$_db, super.$_table, super.$_typedResult);

  static Games _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('analysis__game_id__games__id');

  $GamesProcessedTableManager get gameId {
    final $_column = $_itemColumn<String>('game_id')!;

    final manager = $GamesTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Nodes _nodeIdTable(_$AppDatabase db) =>
      db.nodes.createAlias('analysis__node_id__nodes__id');

  $NodesProcessedTableManager get nodeId {
    final $_column = $_itemColumn<String>('node_id')!;

    final manager = $NodesTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_nodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $AnalysisFilterComposer extends Composer<_$AppDatabase, Analysis> {
  $AnalysisFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get config => $composableBuilder(
    column: $table.config,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  $GamesFilterComposer get gameId {
    final $GamesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $GamesFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $NodesFilterComposer get nodeId {
    final $NodesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $NodesFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AnalysisOrderingComposer extends Composer<_$AppDatabase, Analysis> {
  $AnalysisOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get config => $composableBuilder(
    column: $table.config,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  $GamesOrderingComposer get gameId {
    final $GamesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $GamesOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $NodesOrderingComposer get nodeId {
    final $NodesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $NodesOrderingComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AnalysisAnnotationComposer extends Composer<_$AppDatabase, Analysis> {
  $AnalysisAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get config =>
      $composableBuilder(column: $table.config, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  $GamesAnnotationComposer get gameId {
    final $GamesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $GamesAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $NodesAnnotationComposer get nodeId {
    final $NodesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $NodesAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AnalysisTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Analysis,
          Analysi,
          $AnalysisFilterComposer,
          $AnalysisOrderingComposer,
          $AnalysisAnnotationComposer,
          $AnalysisCreateCompanionBuilder,
          $AnalysisUpdateCompanionBuilder,
          (Analysi, $AnalysisReferences),
          Analysi,
          PrefetchHooks Function({bool gameId, bool nodeId})
        > {
  $AnalysisTableManager(_$AppDatabase db, Analysis table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AnalysisFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AnalysisOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AnalysisAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> gameId = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> config = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnalysisCompanion(
                id: id,
                gameId: gameId,
                nodeId: nodeId,
                config: config,
                data: data,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String gameId,
                required String nodeId,
                required String config,
                required String data,
                Value<int> rowid = const Value.absent(),
              }) => AnalysisCompanion.insert(
                id: id,
                gameId: gameId,
                nodeId: nodeId,
                config: config,
                data: data,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Analysis, Analysi>(table),
                  $AnalysisReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameId = false, nodeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.gameId,
                        referencedTable: $AnalysisReferences._gameIdTable(db),
                        referencedColumn: $AnalysisReferences
                            ._gameIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (nodeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.nodeId,
                        referencedTable: $AnalysisReferences._nodeIdTable(db),
                        referencedColumn: $AnalysisReferences
                            ._nodeIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $AnalysisProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Analysis,
      Analysi,
      $AnalysisFilterComposer,
      $AnalysisOrderingComposer,
      $AnalysisAnnotationComposer,
      $AnalysisCreateCompanionBuilder,
      $AnalysisUpdateCompanionBuilder,
      (Analysi, $AnalysisReferences),
      Analysi,
      PrefetchHooks Function({bool gameId, bool nodeId})
    >;
typedef $RepertoiresCreateCompanionBuilder = RepertoiresCompanion Function({
  required String id,
  required String gameId,
  required String side,
  Value<int> rowid,
});
typedef $RepertoiresUpdateCompanionBuilder = RepertoiresCompanion Function({
  Value<String> id,
  Value<String> gameId,
  Value<String> side,
  Value<int> rowid,
});

final class $RepertoiresReferences
    extends BaseReferences<_$AppDatabase, Repertoires, Repertoire> {
  $RepertoiresReferences(super.$_db, super.$_table, super.$_typedResult);

  static Games _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('repertoires__game_id__games__id');

  $GamesProcessedTableManager get gameId {
    final $_column = $_itemColumn<String>('game_id')!;

    final manager = $GamesTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<Cards, List<Card>> _cardsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.cards,
    aliasName: 'repertoires__id__cards__repertoire_id',
  );

  $CardsProcessedTableManager get cardsRefs {
    final manager = $CardsTableManager(
      $_db,
      $_db.cards,
    ).filter((f) => f.repertoireId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $RepertoiresFilterComposer extends Composer<_$AppDatabase, Repertoires> {
  $RepertoiresFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get side => $composableBuilder(
    column: $table.side,
    builder: (column) => ColumnFilters(column),
  );

  $GamesFilterComposer get gameId {
    final $GamesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $GamesFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> cardsRefs(
    Expression<bool> Function($CardsFilterComposer f) f,
  ) {
    final $CardsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.repertoireId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CardsFilterComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $RepertoiresOrderingComposer
    extends Composer<_$AppDatabase, Repertoires> {
  $RepertoiresOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get side => $composableBuilder(
    column: $table.side,
    builder: (column) => ColumnOrderings(column),
  );

  $GamesOrderingComposer get gameId {
    final $GamesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $GamesOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $RepertoiresAnnotationComposer
    extends Composer<_$AppDatabase, Repertoires> {
  $RepertoiresAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get side =>
      $composableBuilder(column: $table.side, builder: (column) => column);

  $GamesAnnotationComposer get gameId {
    final $GamesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $GamesAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> cardsRefs<T extends Object>(
    Expression<T> Function($CardsAnnotationComposer a) f,
  ) {
    final $CardsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.repertoireId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CardsAnnotationComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $RepertoiresTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Repertoires,
          Repertoire,
          $RepertoiresFilterComposer,
          $RepertoiresOrderingComposer,
          $RepertoiresAnnotationComposer,
          $RepertoiresCreateCompanionBuilder,
          $RepertoiresUpdateCompanionBuilder,
          (Repertoire, $RepertoiresReferences),
          Repertoire,
          PrefetchHooks Function({bool gameId, bool cardsRefs})
        > {
  $RepertoiresTableManager(_$AppDatabase db, Repertoires table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $RepertoiresFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $RepertoiresOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $RepertoiresAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> gameId = const Value.absent(),
                Value<String> side = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RepertoiresCompanion(
                id: id,
                gameId: gameId,
                side: side,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String gameId,
                required String side,
                Value<int> rowid = const Value.absent(),
              }) => RepertoiresCompanion.insert(
                id: id,
                gameId: gameId,
                side: side,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Repertoires, Repertoire>(table),
                  $RepertoiresReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameId = false, cardsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (cardsRefs) db.cards],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.gameId,
                        referencedTable: $RepertoiresReferences._gameIdTable(
                          db,
                        ),
                        referencedColumn: $RepertoiresReferences
                            ._gameIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cardsRefs)
                    await $_getPrefetchedDataByColumns<
                      Repertoire,
                      Repertoires,
                      Card,
                      Cards
                    >(
                      currentTable: table,
                      referencedTable: $RepertoiresReferences._cardsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $RepertoiresReferences(db, table, p0).cardsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'repertoire_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $RepertoiresProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Repertoires,
      Repertoire,
      $RepertoiresFilterComposer,
      $RepertoiresOrderingComposer,
      $RepertoiresAnnotationComposer,
      $RepertoiresCreateCompanionBuilder,
      $RepertoiresUpdateCompanionBuilder,
      (Repertoire, $RepertoiresReferences),
      Repertoire,
      PrefetchHooks Function({bool gameId, bool cardsRefs})
    >;
typedef $CardsCreateCompanionBuilder = CardsCompanion Function({
  required String id,
  required String repertoireId,
  required String fen,
  required String moves,
  Value<int> stage,
  Value<int> due,
  Value<int> rowid,
});
typedef $CardsUpdateCompanionBuilder = CardsCompanion Function({
  Value<String> id,
  Value<String> repertoireId,
  Value<String> fen,
  Value<String> moves,
  Value<int> stage,
  Value<int> due,
  Value<int> rowid,
});

final class $CardsReferences
    extends BaseReferences<_$AppDatabase, Cards, Card> {
  $CardsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Repertoires _repertoireIdTable(_$AppDatabase db) =>
      db.repertoires.createAlias('cards__repertoire_id__repertoires__id');

  $RepertoiresProcessedTableManager get repertoireId {
    final $_column = $_itemColumn<String>('repertoire_id')!;

    final manager = $RepertoiresTableManager(
      $_db,
      $_db.repertoires,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_repertoireIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $CardsFilterComposer extends Composer<_$AppDatabase, Cards> {
  $CardsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fen => $composableBuilder(
    column: $table.fen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moves => $composableBuilder(
    column: $table.moves,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnFilters(column),
  );

  $RepertoiresFilterComposer get repertoireId {
    final $RepertoiresFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.repertoireId,
      referencedTable: $db.repertoires,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RepertoiresFilterComposer(
            $db: $db,
            $table: $db.repertoires,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CardsOrderingComposer extends Composer<_$AppDatabase, Cards> {
  $CardsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fen => $composableBuilder(
    column: $table.fen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moves => $composableBuilder(
    column: $table.moves,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnOrderings(column),
  );

  $RepertoiresOrderingComposer get repertoireId {
    final $RepertoiresOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.repertoireId,
      referencedTable: $db.repertoires,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RepertoiresOrderingComposer(
            $db: $db,
            $table: $db.repertoires,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CardsAnnotationComposer extends Composer<_$AppDatabase, Cards> {
  $CardsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fen =>
      $composableBuilder(column: $table.fen, builder: (column) => column);

  GeneratedColumn<String> get moves =>
      $composableBuilder(column: $table.moves, builder: (column) => column);

  GeneratedColumn<int> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<int> get due =>
      $composableBuilder(column: $table.due, builder: (column) => column);

  $RepertoiresAnnotationComposer get repertoireId {
    final $RepertoiresAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.repertoireId,
      referencedTable: $db.repertoires,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RepertoiresAnnotationComposer(
            $db: $db,
            $table: $db.repertoires,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CardsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Cards,
          Card,
          $CardsFilterComposer,
          $CardsOrderingComposer,
          $CardsAnnotationComposer,
          $CardsCreateCompanionBuilder,
          $CardsUpdateCompanionBuilder,
          (Card, $CardsReferences),
          Card,
          PrefetchHooks Function({bool repertoireId})
        > {
  $CardsTableManager(_$AppDatabase db, Cards table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CardsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CardsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CardsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> repertoireId = const Value.absent(),
                Value<String> fen = const Value.absent(),
                Value<String> moves = const Value.absent(),
                Value<int> stage = const Value.absent(),
                Value<int> due = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardsCompanion(
                id: id,
                repertoireId: repertoireId,
                fen: fen,
                moves: moves,
                stage: stage,
                due: due,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String repertoireId,
                required String fen,
                required String moves,
                Value<int> stage = const Value.absent(),
                Value<int> due = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardsCompanion.insert(
                id: id,
                repertoireId: repertoireId,
                fen: fen,
                moves: moves,
                stage: stage,
                due: due,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Cards, Card>(table),
                  $CardsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({repertoireId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (repertoireId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.repertoireId,
                        referencedTable: $CardsReferences._repertoireIdTable(
                          db,
                        ),
                        referencedColumn: $CardsReferences
                            ._repertoireIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $CardsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Cards,
      Card,
      $CardsFilterComposer,
      $CardsOrderingComposer,
      $CardsAnnotationComposer,
      $CardsCreateCompanionBuilder,
      $CardsUpdateCompanionBuilder,
      (Card, $CardsReferences),
      Card,
      PrefetchHooks Function({bool repertoireId})
    >;
typedef $PuzzlesCreateCompanionBuilder = PuzzlesCompanion Function({
  required String id,
  required String pack,
  required String fen,
  required String moves,
  required int rating,
  required String themes,
  Value<int> rowid,
});
typedef $PuzzlesUpdateCompanionBuilder = PuzzlesCompanion Function({
  Value<String> id,
  Value<String> pack,
  Value<String> fen,
  Value<String> moves,
  Value<int> rating,
  Value<String> themes,
  Value<int> rowid,
});

class $PuzzlesFilterComposer extends Composer<_$AppDatabase, Puzzles> {
  $PuzzlesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pack => $composableBuilder(
    column: $table.pack,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fen => $composableBuilder(
    column: $table.fen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moves => $composableBuilder(
    column: $table.moves,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themes => $composableBuilder(
    column: $table.themes,
    builder: (column) => ColumnFilters(column),
  );
}

class $PuzzlesOrderingComposer extends Composer<_$AppDatabase, Puzzles> {
  $PuzzlesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pack => $composableBuilder(
    column: $table.pack,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fen => $composableBuilder(
    column: $table.fen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moves => $composableBuilder(
    column: $table.moves,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themes => $composableBuilder(
    column: $table.themes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $PuzzlesAnnotationComposer extends Composer<_$AppDatabase, Puzzles> {
  $PuzzlesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pack =>
      $composableBuilder(column: $table.pack, builder: (column) => column);

  GeneratedColumn<String> get fen =>
      $composableBuilder(column: $table.fen, builder: (column) => column);

  GeneratedColumn<String> get moves =>
      $composableBuilder(column: $table.moves, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get themes =>
      $composableBuilder(column: $table.themes, builder: (column) => column);
}

class $PuzzlesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Puzzles,
          Puzzle,
          $PuzzlesFilterComposer,
          $PuzzlesOrderingComposer,
          $PuzzlesAnnotationComposer,
          $PuzzlesCreateCompanionBuilder,
          $PuzzlesUpdateCompanionBuilder,
          (Puzzle, BaseReferences<_$AppDatabase, Puzzles, Puzzle>),
          Puzzle,
          PrefetchHooks Function()
        > {
  $PuzzlesTableManager(_$AppDatabase db, Puzzles table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PuzzlesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PuzzlesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PuzzlesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pack = const Value.absent(),
                Value<String> fen = const Value.absent(),
                Value<String> moves = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<String> themes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuzzlesCompanion(
                id: id,
                pack: pack,
                fen: fen,
                moves: moves,
                rating: rating,
                themes: themes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pack,
                required String fen,
                required String moves,
                required int rating,
                required String themes,
                Value<int> rowid = const Value.absent(),
              }) => PuzzlesCompanion.insert(
                id: id,
                pack: pack,
                fen: fen,
                moves: moves,
                rating: rating,
                themes: themes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Puzzles, Puzzle>(table),
                  BaseReferences<_$AppDatabase, Puzzles, Puzzle>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $PuzzlesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Puzzles,
      Puzzle,
      $PuzzlesFilterComposer,
      $PuzzlesOrderingComposer,
      $PuzzlesAnnotationComposer,
      $PuzzlesCreateCompanionBuilder,
      $PuzzlesUpdateCompanionBuilder,
      (Puzzle, BaseReferences<_$AppDatabase, Puzzles, Puzzle>),
      Puzzle,
      PrefetchHooks Function()
    >;
typedef $PacksCreateCompanionBuilder = PacksCompanion Function({
  required String id,
  required String manifest,
  Value<int> rowid,
});
typedef $PacksUpdateCompanionBuilder = PacksCompanion Function({
  Value<String> id,
  Value<String> manifest,
  Value<int> rowid,
});

class $PacksFilterComposer extends Composer<_$AppDatabase, Packs> {
  $PacksFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manifest => $composableBuilder(
    column: $table.manifest,
    builder: (column) => ColumnFilters(column),
  );
}

class $PacksOrderingComposer extends Composer<_$AppDatabase, Packs> {
  $PacksOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manifest => $composableBuilder(
    column: $table.manifest,
    builder: (column) => ColumnOrderings(column),
  );
}

class $PacksAnnotationComposer extends Composer<_$AppDatabase, Packs> {
  $PacksAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get manifest =>
      $composableBuilder(column: $table.manifest, builder: (column) => column);
}

class $PacksTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Packs,
          Pack,
          $PacksFilterComposer,
          $PacksOrderingComposer,
          $PacksAnnotationComposer,
          $PacksCreateCompanionBuilder,
          $PacksUpdateCompanionBuilder,
          (Pack, BaseReferences<_$AppDatabase, Packs, Pack>),
          Pack,
          PrefetchHooks Function()
        > {
  $PacksTableManager(_$AppDatabase db, Packs table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PacksFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PacksOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PacksAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> manifest = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => PacksCompanion(id: id, manifest: manifest, rowid: rowid),
          createCompanionCallback: ({
            required String id,
            required String manifest,
            Value<int> rowid = const Value.absent(),
          }) => PacksCompanion.insert(id: id, manifest: manifest, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Packs, Pack>(table),
                  BaseReferences<_$AppDatabase, Packs, Pack>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $PacksProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Packs,
      Pack,
      $PacksFilterComposer,
      $PacksOrderingComposer,
      $PacksAnnotationComposer,
      $PacksCreateCompanionBuilder,
      $PacksUpdateCompanionBuilder,
      (Pack, BaseReferences<_$AppDatabase, Packs, Pack>),
      Pack,
      PrefetchHooks Function()
    >;
typedef $AttemptsCreateCompanionBuilder = AttemptsCompanion Function({
  required String id,
  required String kind,
  required String target,
  required int created,
  required int success,
  Value<int> hints,
  Value<int> duration,
  required String metadata,
  Value<int> rowid,
});
typedef $AttemptsUpdateCompanionBuilder = AttemptsCompanion Function({
  Value<String> id,
  Value<String> kind,
  Value<String> target,
  Value<int> created,
  Value<int> success,
  Value<int> hints,
  Value<int> duration,
  Value<String> metadata,
  Value<int> rowid,
});

class $AttemptsFilterComposer extends Composer<_$AppDatabase, Attempts> {
  $AttemptsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get success => $composableBuilder(
    column: $table.success,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hints => $composableBuilder(
    column: $table.hints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );
}

class $AttemptsOrderingComposer extends Composer<_$AppDatabase, Attempts> {
  $AttemptsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get success => $composableBuilder(
    column: $table.success,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hints => $composableBuilder(
    column: $table.hints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );
}

class $AttemptsAnnotationComposer extends Composer<_$AppDatabase, Attempts> {
  $AttemptsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<int> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<int> get success =>
      $composableBuilder(column: $table.success, builder: (column) => column);

  GeneratedColumn<int> get hints =>
      $composableBuilder(column: $table.hints, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);
}

class $AttemptsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Attempts,
          Attempt,
          $AttemptsFilterComposer,
          $AttemptsOrderingComposer,
          $AttemptsAnnotationComposer,
          $AttemptsCreateCompanionBuilder,
          $AttemptsUpdateCompanionBuilder,
          (Attempt, BaseReferences<_$AppDatabase, Attempts, Attempt>),
          Attempt,
          PrefetchHooks Function()
        > {
  $AttemptsTableManager(_$AppDatabase db, Attempts table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AttemptsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AttemptsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AttemptsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> target = const Value.absent(),
                Value<int> created = const Value.absent(),
                Value<int> success = const Value.absent(),
                Value<int> hints = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<String> metadata = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttemptsCompanion(
                id: id,
                kind: kind,
                target: target,
                created: created,
                success: success,
                hints: hints,
                duration: duration,
                metadata: metadata,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String target,
                required int created,
                required int success,
                Value<int> hints = const Value.absent(),
                Value<int> duration = const Value.absent(),
                required String metadata,
                Value<int> rowid = const Value.absent(),
              }) => AttemptsCompanion.insert(
                id: id,
                kind: kind,
                target: target,
                created: created,
                success: success,
                hints: hints,
                duration: duration,
                metadata: metadata,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Attempts, Attempt>(table),
                  BaseReferences<_$AppDatabase, Attempts, Attempt>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $AttemptsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Attempts,
      Attempt,
      $AttemptsFilterComposer,
      $AttemptsOrderingComposer,
      $AttemptsAnnotationComposer,
      $AttemptsCreateCompanionBuilder,
      $AttemptsUpdateCompanionBuilder,
      (Attempt, BaseReferences<_$AppDatabase, Attempts, Attempt>),
      Attempt,
      PrefetchHooks Function()
    >;
typedef $PreferencesCreateCompanionBuilder = PreferencesCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $PreferencesUpdateCompanionBuilder = PreferencesCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $PreferencesFilterComposer extends Composer<_$AppDatabase, Preferences> {
  $PreferencesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $PreferencesOrderingComposer
    extends Composer<_$AppDatabase, Preferences> {
  $PreferencesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $PreferencesAnnotationComposer
    extends Composer<_$AppDatabase, Preferences> {
  $PreferencesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $PreferencesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Preferences,
          Preference,
          $PreferencesFilterComposer,
          $PreferencesOrderingComposer,
          $PreferencesAnnotationComposer,
          $PreferencesCreateCompanionBuilder,
          $PreferencesUpdateCompanionBuilder,
          (Preference, BaseReferences<_$AppDatabase, Preferences, Preference>),
          Preference,
          PrefetchHooks Function()
        > {
  $PreferencesTableManager(_$AppDatabase db, Preferences table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PreferencesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PreferencesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PreferencesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => PreferencesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Preferences, Preference>(table),
                  BaseReferences<_$AppDatabase, Preferences, Preference>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $PreferencesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Preferences,
      Preference,
      $PreferencesFilterComposer,
      $PreferencesOrderingComposer,
      $PreferencesAnnotationComposer,
      $PreferencesCreateCompanionBuilder,
      $PreferencesUpdateCompanionBuilder,
      (Preference, BaseReferences<_$AppDatabase, Preferences, Preference>),
      Preference,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $GamesTableManager get games => $GamesTableManager(_db, _db.games);
  $NodesTableManager get nodes => $NodesTableManager(_db, _db.nodes);
  $AnalysisTableManager get analysis =>
      $AnalysisTableManager(_db, _db.analysis);
  $RepertoiresTableManager get repertoires =>
      $RepertoiresTableManager(_db, _db.repertoires);
  $CardsTableManager get cards => $CardsTableManager(_db, _db.cards);
  $PuzzlesTableManager get puzzles => $PuzzlesTableManager(_db, _db.puzzles);
  $PacksTableManager get packs => $PacksTableManager(_db, _db.packs);
  $AttemptsTableManager get attempts =>
      $AttemptsTableManager(_db, _db.attempts);
  $PreferencesTableManager get preferences =>
      $PreferencesTableManager(_db, _db.preferences);
}
