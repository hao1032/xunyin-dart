// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SeriesTableTable extends SeriesTable
    with TableInfo<$SeriesTableTable, SeriesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesKindMeta = const VerificationMeta(
    'seriesKind',
  );
  @override
  late final GeneratedColumn<String> seriesKind = GeneratedColumn<String>(
    'series_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceSeriesIdMeta = const VerificationMeta(
    'sourceSeriesId',
  );
  @override
  late final GeneratedColumn<String> sourceSeriesId = GeneratedColumn<String>(
    'source_series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalUrlMeta = const VerificationMeta(
    'originalUrl',
  );
  @override
  late final GeneratedColumn<String> originalUrl = GeneratedColumn<String>(
    'original_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _feedUrlMeta = const VerificationMeta(
    'feedUrl',
  );
  @override
  late final GeneratedColumn<String> feedUrl = GeneratedColumn<String>(
    'feed_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceType,
    seriesKind,
    sourceSeriesId,
    sortOrder,
    title,
    author,
    description,
    imageUrl,
    originalUrl,
    feedUrl,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'series';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeriesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('series_kind')) {
      context.handle(
        _seriesKindMeta,
        seriesKind.isAcceptableOrUnknown(data['series_kind']!, _seriesKindMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesKindMeta);
    }
    if (data.containsKey('source_series_id')) {
      context.handle(
        _sourceSeriesIdMeta,
        sourceSeriesId.isAcceptableOrUnknown(
          data['source_series_id']!,
          _sourceSeriesIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceSeriesIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('original_url')) {
      context.handle(
        _originalUrlMeta,
        originalUrl.isAcceptableOrUnknown(
          data['original_url']!,
          _originalUrlMeta,
        ),
      );
    }
    if (data.containsKey('feed_url')) {
      context.handle(
        _feedUrlMeta,
        feedUrl.isAcceptableOrUnknown(data['feed_url']!, _feedUrlMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sourceType, seriesKind, sourceSeriesId},
  ];
  @override
  SeriesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      seriesKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_kind'],
      )!,
      sourceSeriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_series_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      originalUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_url'],
      ),
      feedUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feed_url'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SeriesTableTable createAlias(String alias) {
    return $SeriesTableTable(attachedDatabase, alias);
  }
}

class SeriesRow extends DataClass implements Insertable<SeriesRow> {
  final int id;
  final String sourceType;
  final String seriesKind;
  final String sourceSeriesId;
  final int sortOrder;
  final String title;
  final String? author;
  final String? description;
  final String? imageUrl;
  final String? originalUrl;
  final String? feedUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SeriesRow({
    required this.id,
    required this.sourceType,
    required this.seriesKind,
    required this.sourceSeriesId,
    required this.sortOrder,
    required this.title,
    this.author,
    this.description,
    this.imageUrl,
    this.originalUrl,
    this.feedUrl,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_type'] = Variable<String>(sourceType);
    map['series_kind'] = Variable<String>(seriesKind);
    map['source_series_id'] = Variable<String>(sourceSeriesId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || originalUrl != null) {
      map['original_url'] = Variable<String>(originalUrl);
    }
    if (!nullToAbsent || feedUrl != null) {
      map['feed_url'] = Variable<String>(feedUrl);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SeriesTableCompanion toCompanion(bool nullToAbsent) {
    return SeriesTableCompanion(
      id: Value(id),
      sourceType: Value(sourceType),
      seriesKind: Value(seriesKind),
      sourceSeriesId: Value(sourceSeriesId),
      sortOrder: Value(sortOrder),
      title: Value(title),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      originalUrl: originalUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(originalUrl),
      feedUrl: feedUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(feedUrl),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SeriesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesRow(
      id: serializer.fromJson<int>(json['id']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      seriesKind: serializer.fromJson<String>(json['seriesKind']),
      sourceSeriesId: serializer.fromJson<String>(json['sourceSeriesId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      description: serializer.fromJson<String?>(json['description']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      originalUrl: serializer.fromJson<String?>(json['originalUrl']),
      feedUrl: serializer.fromJson<String?>(json['feedUrl']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceType': serializer.toJson<String>(sourceType),
      'seriesKind': serializer.toJson<String>(seriesKind),
      'sourceSeriesId': serializer.toJson<String>(sourceSeriesId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'description': serializer.toJson<String?>(description),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'originalUrl': serializer.toJson<String?>(originalUrl),
      'feedUrl': serializer.toJson<String?>(feedUrl),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SeriesRow copyWith({
    int? id,
    String? sourceType,
    String? seriesKind,
    String? sourceSeriesId,
    int? sortOrder,
    String? title,
    Value<String?> author = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> originalUrl = const Value.absent(),
    Value<String?> feedUrl = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SeriesRow(
    id: id ?? this.id,
    sourceType: sourceType ?? this.sourceType,
    seriesKind: seriesKind ?? this.seriesKind,
    sourceSeriesId: sourceSeriesId ?? this.sourceSeriesId,
    sortOrder: sortOrder ?? this.sortOrder,
    title: title ?? this.title,
    author: author.present ? author.value : this.author,
    description: description.present ? description.value : this.description,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    originalUrl: originalUrl.present ? originalUrl.value : this.originalUrl,
    feedUrl: feedUrl.present ? feedUrl.value : this.feedUrl,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SeriesRow copyWithCompanion(SeriesTableCompanion data) {
    return SeriesRow(
      id: data.id.present ? data.id.value : this.id,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      seriesKind: data.seriesKind.present
          ? data.seriesKind.value
          : this.seriesKind,
      sourceSeriesId: data.sourceSeriesId.present
          ? data.sourceSeriesId.value
          : this.sourceSeriesId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      description: data.description.present
          ? data.description.value
          : this.description,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      originalUrl: data.originalUrl.present
          ? data.originalUrl.value
          : this.originalUrl,
      feedUrl: data.feedUrl.present ? data.feedUrl.value : this.feedUrl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesRow(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('seriesKind: $seriesKind, ')
          ..write('sourceSeriesId: $sourceSeriesId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('originalUrl: $originalUrl, ')
          ..write('feedUrl: $feedUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceType,
    seriesKind,
    sourceSeriesId,
    sortOrder,
    title,
    author,
    description,
    imageUrl,
    originalUrl,
    feedUrl,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesRow &&
          other.id == this.id &&
          other.sourceType == this.sourceType &&
          other.seriesKind == this.seriesKind &&
          other.sourceSeriesId == this.sourceSeriesId &&
          other.sortOrder == this.sortOrder &&
          other.title == this.title &&
          other.author == this.author &&
          other.description == this.description &&
          other.imageUrl == this.imageUrl &&
          other.originalUrl == this.originalUrl &&
          other.feedUrl == this.feedUrl &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SeriesTableCompanion extends UpdateCompanion<SeriesRow> {
  final Value<int> id;
  final Value<String> sourceType;
  final Value<String> seriesKind;
  final Value<String> sourceSeriesId;
  final Value<int> sortOrder;
  final Value<String> title;
  final Value<String?> author;
  final Value<String?> description;
  final Value<String?> imageUrl;
  final Value<String?> originalUrl;
  final Value<String?> feedUrl;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SeriesTableCompanion({
    this.id = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.seriesKind = const Value.absent(),
    this.sourceSeriesId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.originalUrl = const Value.absent(),
    this.feedUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SeriesTableCompanion.insert({
    this.id = const Value.absent(),
    required String sourceType,
    required String seriesKind,
    required String sourceSeriesId,
    required int sortOrder,
    required String title,
    this.author = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.originalUrl = const Value.absent(),
    this.feedUrl = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : sourceType = Value(sourceType),
       seriesKind = Value(seriesKind),
       sourceSeriesId = Value(sourceSeriesId),
       sortOrder = Value(sortOrder),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SeriesRow> custom({
    Expression<int>? id,
    Expression<String>? sourceType,
    Expression<String>? seriesKind,
    Expression<String>? sourceSeriesId,
    Expression<int>? sortOrder,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? description,
    Expression<String>? imageUrl,
    Expression<String>? originalUrl,
    Expression<String>? feedUrl,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceType != null) 'source_type': sourceType,
      if (seriesKind != null) 'series_kind': seriesKind,
      if (sourceSeriesId != null) 'source_series_id': sourceSeriesId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (originalUrl != null) 'original_url': originalUrl,
      if (feedUrl != null) 'feed_url': feedUrl,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SeriesTableCompanion copyWith({
    Value<int>? id,
    Value<String>? sourceType,
    Value<String>? seriesKind,
    Value<String>? sourceSeriesId,
    Value<int>? sortOrder,
    Value<String>? title,
    Value<String?>? author,
    Value<String?>? description,
    Value<String?>? imageUrl,
    Value<String?>? originalUrl,
    Value<String?>? feedUrl,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SeriesTableCompanion(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      seriesKind: seriesKind ?? this.seriesKind,
      sourceSeriesId: sourceSeriesId ?? this.sourceSeriesId,
      sortOrder: sortOrder ?? this.sortOrder,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      originalUrl: originalUrl ?? this.originalUrl,
      feedUrl: feedUrl ?? this.feedUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (seriesKind.present) {
      map['series_kind'] = Variable<String>(seriesKind.value);
    }
    if (sourceSeriesId.present) {
      map['source_series_id'] = Variable<String>(sourceSeriesId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (originalUrl.present) {
      map['original_url'] = Variable<String>(originalUrl.value);
    }
    if (feedUrl.present) {
      map['feed_url'] = Variable<String>(feedUrl.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeriesTableCompanion(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('seriesKind: $seriesKind, ')
          ..write('sourceSeriesId: $sourceSeriesId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('originalUrl: $originalUrl, ')
          ..write('feedUrl: $feedUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $EpisodesTableTable extends EpisodesTable
    with TableInfo<$EpisodesTableTable, EpisodeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<int> seriesId = GeneratedColumn<int>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceEpisodeIdMeta = const VerificationMeta(
    'sourceEpisodeId',
  );
  @override
  late final GeneratedColumn<String> sourceEpisodeId = GeneratedColumn<String>(
    'source_episode_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalUrlMeta = const VerificationMeta(
    'originalUrl',
  );
  @override
  late final GeneratedColumn<String> originalUrl = GeneratedColumn<String>(
    'original_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioUrlMeta = const VerificationMeta(
    'audioUrl',
  );
  @override
  late final GeneratedColumn<String> audioUrl = GeneratedColumn<String>(
    'audio_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoUrlMeta = const VerificationMeta(
    'videoUrl',
  );
  @override
  late final GeneratedColumn<String> videoUrl = GeneratedColumn<String>(
    'video_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioBytesMeta = const VerificationMeta(
    'audioBytes',
  );
  @override
  late final GeneratedColumn<int> audioBytes = GeneratedColumn<int>(
    'audio_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
    'published_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bilibiliBvidMeta = const VerificationMeta(
    'bilibiliBvid',
  );
  @override
  late final GeneratedColumn<String> bilibiliBvid = GeneratedColumn<String>(
    'bilibili_bvid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bilibiliAidMeta = const VerificationMeta(
    'bilibiliAid',
  );
  @override
  late final GeneratedColumn<int> bilibiliAid = GeneratedColumn<int>(
    'bilibili_aid',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bilibiliCidMeta = const VerificationMeta(
    'bilibiliCid',
  );
  @override
  late final GeneratedColumn<int> bilibiliCid = GeneratedColumn<int>(
    'bilibili_cid',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bilibiliPageMeta = const VerificationMeta(
    'bilibiliPage',
  );
  @override
  late final GeneratedColumn<int> bilibiliPage = GeneratedColumn<int>(
    'bilibili_page',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _progressMsMeta = const VerificationMeta(
    'progressMs',
  );
  @override
  late final GeneratedColumn<int> progressMs = GeneratedColumn<int>(
    'progress_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    seriesId,
    sourceType,
    sourceEpisodeId,
    sortOrder,
    title,
    author,
    description,
    imageUrl,
    originalUrl,
    audioUrl,
    videoUrl,
    durationMs,
    audioBytes,
    publishedAt,
    bilibiliBvid,
    bilibiliAid,
    bilibiliCid,
    bilibiliPage,
    progressMs,
    lastPlayedAt,
    isCompleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpisodeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('source_episode_id')) {
      context.handle(
        _sourceEpisodeIdMeta,
        sourceEpisodeId.isAcceptableOrUnknown(
          data['source_episode_id']!,
          _sourceEpisodeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceEpisodeIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('original_url')) {
      context.handle(
        _originalUrlMeta,
        originalUrl.isAcceptableOrUnknown(
          data['original_url']!,
          _originalUrlMeta,
        ),
      );
    }
    if (data.containsKey('audio_url')) {
      context.handle(
        _audioUrlMeta,
        audioUrl.isAcceptableOrUnknown(data['audio_url']!, _audioUrlMeta),
      );
    }
    if (data.containsKey('video_url')) {
      context.handle(
        _videoUrlMeta,
        videoUrl.isAcceptableOrUnknown(data['video_url']!, _videoUrlMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('audio_bytes')) {
      context.handle(
        _audioBytesMeta,
        audioBytes.isAcceptableOrUnknown(data['audio_bytes']!, _audioBytesMeta),
      );
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    }
    if (data.containsKey('bilibili_bvid')) {
      context.handle(
        _bilibiliBvidMeta,
        bilibiliBvid.isAcceptableOrUnknown(
          data['bilibili_bvid']!,
          _bilibiliBvidMeta,
        ),
      );
    }
    if (data.containsKey('bilibili_aid')) {
      context.handle(
        _bilibiliAidMeta,
        bilibiliAid.isAcceptableOrUnknown(
          data['bilibili_aid']!,
          _bilibiliAidMeta,
        ),
      );
    }
    if (data.containsKey('bilibili_cid')) {
      context.handle(
        _bilibiliCidMeta,
        bilibiliCid.isAcceptableOrUnknown(
          data['bilibili_cid']!,
          _bilibiliCidMeta,
        ),
      );
    }
    if (data.containsKey('bilibili_page')) {
      context.handle(
        _bilibiliPageMeta,
        bilibiliPage.isAcceptableOrUnknown(
          data['bilibili_page']!,
          _bilibiliPageMeta,
        ),
      );
    }
    if (data.containsKey('progress_ms')) {
      context.handle(
        _progressMsMeta,
        progressMs.isAcceptableOrUnknown(data['progress_ms']!, _progressMsMeta),
      );
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EpisodeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpisodeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_id'],
      ),
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourceEpisodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_episode_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      originalUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_url'],
      ),
      audioUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_url'],
      ),
      videoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_url'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      audioBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}audio_bytes'],
      ),
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}published_at'],
      ),
      bilibiliBvid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bilibili_bvid'],
      ),
      bilibiliAid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bilibili_aid'],
      ),
      bilibiliCid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bilibili_cid'],
      ),
      bilibiliPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bilibili_page'],
      ),
      progressMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progress_ms'],
      )!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      ),
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EpisodesTableTable createAlias(String alias) {
    return $EpisodesTableTable(attachedDatabase, alias);
  }
}

class EpisodeRow extends DataClass implements Insertable<EpisodeRow> {
  final int id;
  final int? seriesId;
  final String sourceType;
  final String sourceEpisodeId;
  final int sortOrder;
  final String title;
  final String? author;
  final String? description;
  final String? imageUrl;
  final String? originalUrl;
  final String? audioUrl;
  final String? videoUrl;
  final int? durationMs;
  final int? audioBytes;
  final DateTime? publishedAt;
  final String? bilibiliBvid;
  final int? bilibiliAid;
  final int? bilibiliCid;
  final int? bilibiliPage;
  final int progressMs;
  final DateTime? lastPlayedAt;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const EpisodeRow({
    required this.id,
    this.seriesId,
    required this.sourceType,
    required this.sourceEpisodeId,
    required this.sortOrder,
    required this.title,
    this.author,
    this.description,
    this.imageUrl,
    this.originalUrl,
    this.audioUrl,
    this.videoUrl,
    this.durationMs,
    this.audioBytes,
    this.publishedAt,
    this.bilibiliBvid,
    this.bilibiliAid,
    this.bilibiliCid,
    this.bilibiliPage,
    required this.progressMs,
    this.lastPlayedAt,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<int>(seriesId);
    }
    map['source_type'] = Variable<String>(sourceType);
    map['source_episode_id'] = Variable<String>(sourceEpisodeId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || originalUrl != null) {
      map['original_url'] = Variable<String>(originalUrl);
    }
    if (!nullToAbsent || audioUrl != null) {
      map['audio_url'] = Variable<String>(audioUrl);
    }
    if (!nullToAbsent || videoUrl != null) {
      map['video_url'] = Variable<String>(videoUrl);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || audioBytes != null) {
      map['audio_bytes'] = Variable<int>(audioBytes);
    }
    if (!nullToAbsent || publishedAt != null) {
      map['published_at'] = Variable<DateTime>(publishedAt);
    }
    if (!nullToAbsent || bilibiliBvid != null) {
      map['bilibili_bvid'] = Variable<String>(bilibiliBvid);
    }
    if (!nullToAbsent || bilibiliAid != null) {
      map['bilibili_aid'] = Variable<int>(bilibiliAid);
    }
    if (!nullToAbsent || bilibiliCid != null) {
      map['bilibili_cid'] = Variable<int>(bilibiliCid);
    }
    if (!nullToAbsent || bilibiliPage != null) {
      map['bilibili_page'] = Variable<int>(bilibiliPage);
    }
    map['progress_ms'] = Variable<int>(progressMs);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EpisodesTableCompanion toCompanion(bool nullToAbsent) {
    return EpisodesTableCompanion(
      id: Value(id),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      sourceType: Value(sourceType),
      sourceEpisodeId: Value(sourceEpisodeId),
      sortOrder: Value(sortOrder),
      title: Value(title),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      originalUrl: originalUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(originalUrl),
      audioUrl: audioUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(audioUrl),
      videoUrl: videoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(videoUrl),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      audioBytes: audioBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(audioBytes),
      publishedAt: publishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(publishedAt),
      bilibiliBvid: bilibiliBvid == null && nullToAbsent
          ? const Value.absent()
          : Value(bilibiliBvid),
      bilibiliAid: bilibiliAid == null && nullToAbsent
          ? const Value.absent()
          : Value(bilibiliAid),
      bilibiliCid: bilibiliCid == null && nullToAbsent
          ? const Value.absent()
          : Value(bilibiliCid),
      bilibiliPage: bilibiliPage == null && nullToAbsent
          ? const Value.absent()
          : Value(bilibiliPage),
      progressMs: Value(progressMs),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
      isCompleted: Value(isCompleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory EpisodeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpisodeRow(
      id: serializer.fromJson<int>(json['id']),
      seriesId: serializer.fromJson<int?>(json['seriesId']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceEpisodeId: serializer.fromJson<String>(json['sourceEpisodeId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      description: serializer.fromJson<String?>(json['description']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      originalUrl: serializer.fromJson<String?>(json['originalUrl']),
      audioUrl: serializer.fromJson<String?>(json['audioUrl']),
      videoUrl: serializer.fromJson<String?>(json['videoUrl']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      audioBytes: serializer.fromJson<int?>(json['audioBytes']),
      publishedAt: serializer.fromJson<DateTime?>(json['publishedAt']),
      bilibiliBvid: serializer.fromJson<String?>(json['bilibiliBvid']),
      bilibiliAid: serializer.fromJson<int?>(json['bilibiliAid']),
      bilibiliCid: serializer.fromJson<int?>(json['bilibiliCid']),
      bilibiliPage: serializer.fromJson<int?>(json['bilibiliPage']),
      progressMs: serializer.fromJson<int>(json['progressMs']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'seriesId': serializer.toJson<int?>(seriesId),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceEpisodeId': serializer.toJson<String>(sourceEpisodeId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'description': serializer.toJson<String?>(description),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'originalUrl': serializer.toJson<String?>(originalUrl),
      'audioUrl': serializer.toJson<String?>(audioUrl),
      'videoUrl': serializer.toJson<String?>(videoUrl),
      'durationMs': serializer.toJson<int?>(durationMs),
      'audioBytes': serializer.toJson<int?>(audioBytes),
      'publishedAt': serializer.toJson<DateTime?>(publishedAt),
      'bilibiliBvid': serializer.toJson<String?>(bilibiliBvid),
      'bilibiliAid': serializer.toJson<int?>(bilibiliAid),
      'bilibiliCid': serializer.toJson<int?>(bilibiliCid),
      'bilibiliPage': serializer.toJson<int?>(bilibiliPage),
      'progressMs': serializer.toJson<int>(progressMs),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EpisodeRow copyWith({
    int? id,
    Value<int?> seriesId = const Value.absent(),
    String? sourceType,
    String? sourceEpisodeId,
    int? sortOrder,
    String? title,
    Value<String?> author = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> originalUrl = const Value.absent(),
    Value<String?> audioUrl = const Value.absent(),
    Value<String?> videoUrl = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    Value<int?> audioBytes = const Value.absent(),
    Value<DateTime?> publishedAt = const Value.absent(),
    Value<String?> bilibiliBvid = const Value.absent(),
    Value<int?> bilibiliAid = const Value.absent(),
    Value<int?> bilibiliCid = const Value.absent(),
    Value<int?> bilibiliPage = const Value.absent(),
    int? progressMs,
    Value<DateTime?> lastPlayedAt = const Value.absent(),
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => EpisodeRow(
    id: id ?? this.id,
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
    sourceType: sourceType ?? this.sourceType,
    sourceEpisodeId: sourceEpisodeId ?? this.sourceEpisodeId,
    sortOrder: sortOrder ?? this.sortOrder,
    title: title ?? this.title,
    author: author.present ? author.value : this.author,
    description: description.present ? description.value : this.description,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    originalUrl: originalUrl.present ? originalUrl.value : this.originalUrl,
    audioUrl: audioUrl.present ? audioUrl.value : this.audioUrl,
    videoUrl: videoUrl.present ? videoUrl.value : this.videoUrl,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    audioBytes: audioBytes.present ? audioBytes.value : this.audioBytes,
    publishedAt: publishedAt.present ? publishedAt.value : this.publishedAt,
    bilibiliBvid: bilibiliBvid.present ? bilibiliBvid.value : this.bilibiliBvid,
    bilibiliAid: bilibiliAid.present ? bilibiliAid.value : this.bilibiliAid,
    bilibiliCid: bilibiliCid.present ? bilibiliCid.value : this.bilibiliCid,
    bilibiliPage: bilibiliPage.present ? bilibiliPage.value : this.bilibiliPage,
    progressMs: progressMs ?? this.progressMs,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EpisodeRow copyWithCompanion(EpisodesTableCompanion data) {
    return EpisodeRow(
      id: data.id.present ? data.id.value : this.id,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceEpisodeId: data.sourceEpisodeId.present
          ? data.sourceEpisodeId.value
          : this.sourceEpisodeId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      description: data.description.present
          ? data.description.value
          : this.description,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      originalUrl: data.originalUrl.present
          ? data.originalUrl.value
          : this.originalUrl,
      audioUrl: data.audioUrl.present ? data.audioUrl.value : this.audioUrl,
      videoUrl: data.videoUrl.present ? data.videoUrl.value : this.videoUrl,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      audioBytes: data.audioBytes.present
          ? data.audioBytes.value
          : this.audioBytes,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
      bilibiliBvid: data.bilibiliBvid.present
          ? data.bilibiliBvid.value
          : this.bilibiliBvid,
      bilibiliAid: data.bilibiliAid.present
          ? data.bilibiliAid.value
          : this.bilibiliAid,
      bilibiliCid: data.bilibiliCid.present
          ? data.bilibiliCid.value
          : this.bilibiliCid,
      bilibiliPage: data.bilibiliPage.present
          ? data.bilibiliPage.value
          : this.bilibiliPage,
      progressMs: data.progressMs.present
          ? data.progressMs.value
          : this.progressMs,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpisodeRow(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceEpisodeId: $sourceEpisodeId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('originalUrl: $originalUrl, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('durationMs: $durationMs, ')
          ..write('audioBytes: $audioBytes, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('bilibiliBvid: $bilibiliBvid, ')
          ..write('bilibiliAid: $bilibiliAid, ')
          ..write('bilibiliCid: $bilibiliCid, ')
          ..write('bilibiliPage: $bilibiliPage, ')
          ..write('progressMs: $progressMs, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    seriesId,
    sourceType,
    sourceEpisodeId,
    sortOrder,
    title,
    author,
    description,
    imageUrl,
    originalUrl,
    audioUrl,
    videoUrl,
    durationMs,
    audioBytes,
    publishedAt,
    bilibiliBvid,
    bilibiliAid,
    bilibiliCid,
    bilibiliPage,
    progressMs,
    lastPlayedAt,
    isCompleted,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpisodeRow &&
          other.id == this.id &&
          other.seriesId == this.seriesId &&
          other.sourceType == this.sourceType &&
          other.sourceEpisodeId == this.sourceEpisodeId &&
          other.sortOrder == this.sortOrder &&
          other.title == this.title &&
          other.author == this.author &&
          other.description == this.description &&
          other.imageUrl == this.imageUrl &&
          other.originalUrl == this.originalUrl &&
          other.audioUrl == this.audioUrl &&
          other.videoUrl == this.videoUrl &&
          other.durationMs == this.durationMs &&
          other.audioBytes == this.audioBytes &&
          other.publishedAt == this.publishedAt &&
          other.bilibiliBvid == this.bilibiliBvid &&
          other.bilibiliAid == this.bilibiliAid &&
          other.bilibiliCid == this.bilibiliCid &&
          other.bilibiliPage == this.bilibiliPage &&
          other.progressMs == this.progressMs &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.isCompleted == this.isCompleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EpisodesTableCompanion extends UpdateCompanion<EpisodeRow> {
  final Value<int> id;
  final Value<int?> seriesId;
  final Value<String> sourceType;
  final Value<String> sourceEpisodeId;
  final Value<int> sortOrder;
  final Value<String> title;
  final Value<String?> author;
  final Value<String?> description;
  final Value<String?> imageUrl;
  final Value<String?> originalUrl;
  final Value<String?> audioUrl;
  final Value<String?> videoUrl;
  final Value<int?> durationMs;
  final Value<int?> audioBytes;
  final Value<DateTime?> publishedAt;
  final Value<String?> bilibiliBvid;
  final Value<int?> bilibiliAid;
  final Value<int?> bilibiliCid;
  final Value<int?> bilibiliPage;
  final Value<int> progressMs;
  final Value<DateTime?> lastPlayedAt;
  final Value<bool> isCompleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const EpisodesTableCompanion({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceEpisodeId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.originalUrl = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.audioBytes = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.bilibiliBvid = const Value.absent(),
    this.bilibiliAid = const Value.absent(),
    this.bilibiliCid = const Value.absent(),
    this.bilibiliPage = const Value.absent(),
    this.progressMs = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  EpisodesTableCompanion.insert({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    required String sourceType,
    required String sourceEpisodeId,
    required int sortOrder,
    required String title,
    this.author = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.originalUrl = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.audioBytes = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.bilibiliBvid = const Value.absent(),
    this.bilibiliAid = const Value.absent(),
    this.bilibiliCid = const Value.absent(),
    this.bilibiliPage = const Value.absent(),
    this.progressMs = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.isCompleted = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : sourceType = Value(sourceType),
       sourceEpisodeId = Value(sourceEpisodeId),
       sortOrder = Value(sortOrder),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<EpisodeRow> custom({
    Expression<int>? id,
    Expression<int>? seriesId,
    Expression<String>? sourceType,
    Expression<String>? sourceEpisodeId,
    Expression<int>? sortOrder,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? description,
    Expression<String>? imageUrl,
    Expression<String>? originalUrl,
    Expression<String>? audioUrl,
    Expression<String>? videoUrl,
    Expression<int>? durationMs,
    Expression<int>? audioBytes,
    Expression<DateTime>? publishedAt,
    Expression<String>? bilibiliBvid,
    Expression<int>? bilibiliAid,
    Expression<int>? bilibiliCid,
    Expression<int>? bilibiliPage,
    Expression<int>? progressMs,
    Expression<DateTime>? lastPlayedAt,
    Expression<bool>? isCompleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesId != null) 'series_id': seriesId,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceEpisodeId != null) 'source_episode_id': sourceEpisodeId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (originalUrl != null) 'original_url': originalUrl,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (videoUrl != null) 'video_url': videoUrl,
      if (durationMs != null) 'duration_ms': durationMs,
      if (audioBytes != null) 'audio_bytes': audioBytes,
      if (publishedAt != null) 'published_at': publishedAt,
      if (bilibiliBvid != null) 'bilibili_bvid': bilibiliBvid,
      if (bilibiliAid != null) 'bilibili_aid': bilibiliAid,
      if (bilibiliCid != null) 'bilibili_cid': bilibiliCid,
      if (bilibiliPage != null) 'bilibili_page': bilibiliPage,
      if (progressMs != null) 'progress_ms': progressMs,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  EpisodesTableCompanion copyWith({
    Value<int>? id,
    Value<int?>? seriesId,
    Value<String>? sourceType,
    Value<String>? sourceEpisodeId,
    Value<int>? sortOrder,
    Value<String>? title,
    Value<String?>? author,
    Value<String?>? description,
    Value<String?>? imageUrl,
    Value<String?>? originalUrl,
    Value<String?>? audioUrl,
    Value<String?>? videoUrl,
    Value<int?>? durationMs,
    Value<int?>? audioBytes,
    Value<DateTime?>? publishedAt,
    Value<String?>? bilibiliBvid,
    Value<int?>? bilibiliAid,
    Value<int?>? bilibiliCid,
    Value<int?>? bilibiliPage,
    Value<int>? progressMs,
    Value<DateTime?>? lastPlayedAt,
    Value<bool>? isCompleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return EpisodesTableCompanion(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      sourceType: sourceType ?? this.sourceType,
      sourceEpisodeId: sourceEpisodeId ?? this.sourceEpisodeId,
      sortOrder: sortOrder ?? this.sortOrder,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      originalUrl: originalUrl ?? this.originalUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      durationMs: durationMs ?? this.durationMs,
      audioBytes: audioBytes ?? this.audioBytes,
      publishedAt: publishedAt ?? this.publishedAt,
      bilibiliBvid: bilibiliBvid ?? this.bilibiliBvid,
      bilibiliAid: bilibiliAid ?? this.bilibiliAid,
      bilibiliCid: bilibiliCid ?? this.bilibiliCid,
      bilibiliPage: bilibiliPage ?? this.bilibiliPage,
      progressMs: progressMs ?? this.progressMs,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<int>(seriesId.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceEpisodeId.present) {
      map['source_episode_id'] = Variable<String>(sourceEpisodeId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (originalUrl.present) {
      map['original_url'] = Variable<String>(originalUrl.value);
    }
    if (audioUrl.present) {
      map['audio_url'] = Variable<String>(audioUrl.value);
    }
    if (videoUrl.present) {
      map['video_url'] = Variable<String>(videoUrl.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (audioBytes.present) {
      map['audio_bytes'] = Variable<int>(audioBytes.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    if (bilibiliBvid.present) {
      map['bilibili_bvid'] = Variable<String>(bilibiliBvid.value);
    }
    if (bilibiliAid.present) {
      map['bilibili_aid'] = Variable<int>(bilibiliAid.value);
    }
    if (bilibiliCid.present) {
      map['bilibili_cid'] = Variable<int>(bilibiliCid.value);
    }
    if (bilibiliPage.present) {
      map['bilibili_page'] = Variable<int>(bilibiliPage.value);
    }
    if (progressMs.present) {
      map['progress_ms'] = Variable<int>(progressMs.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesTableCompanion(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceEpisodeId: $sourceEpisodeId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('originalUrl: $originalUrl, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('durationMs: $durationMs, ')
          ..write('audioBytes: $audioBytes, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('bilibiliBvid: $bilibiliBvid, ')
          ..write('bilibiliAid: $bilibiliAid, ')
          ..write('bilibiliCid: $bilibiliCid, ')
          ..write('bilibiliPage: $bilibiliPage, ')
          ..write('progressMs: $progressMs, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DownloadsTableTable extends DownloadsTable
    with TableInfo<$DownloadsTableTable, DownloadRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceEpisodeIdMeta = const VerificationMeta(
    'sourceEpisodeId',
  );
  @override
  late final GeneratedColumn<String> sourceEpisodeId = GeneratedColumn<String>(
    'source_episode_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
    'bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('downloading'),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceType,
    sourceEpisodeId,
    filePath,
    bytes,
    status,
    errorMessage,
    downloadedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('source_episode_id')) {
      context.handle(
        _sourceEpisodeIdMeta,
        sourceEpisodeId.isAcceptableOrUnknown(
          data['source_episode_id']!,
          _sourceEpisodeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceEpisodeIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sourceType, sourceEpisodeId},
  ];
  @override
  DownloadRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourceEpisodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_episode_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      ),
    );
  }

  @override
  $DownloadsTableTable createAlias(String alias) {
    return $DownloadsTableTable(attachedDatabase, alias);
  }
}

class DownloadRow extends DataClass implements Insertable<DownloadRow> {
  final int id;
  final String sourceType;
  final String sourceEpisodeId;
  final String? filePath;
  final int? bytes;
  final String status;
  final String? errorMessage;
  final DateTime? downloadedAt;
  const DownloadRow({
    required this.id,
    required this.sourceType,
    required this.sourceEpisodeId,
    this.filePath,
    this.bytes,
    required this.status,
    this.errorMessage,
    this.downloadedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_type'] = Variable<String>(sourceType);
    map['source_episode_id'] = Variable<String>(sourceEpisodeId);
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || bytes != null) {
      map['bytes'] = Variable<int>(bytes);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || downloadedAt != null) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    }
    return map;
  }

  DownloadsTableCompanion toCompanion(bool nullToAbsent) {
    return DownloadsTableCompanion(
      id: Value(id),
      sourceType: Value(sourceType),
      sourceEpisodeId: Value(sourceEpisodeId),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      bytes: bytes == null && nullToAbsent
          ? const Value.absent()
          : Value(bytes),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      downloadedAt: downloadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadedAt),
    );
  }

  factory DownloadRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadRow(
      id: serializer.fromJson<int>(json['id']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceEpisodeId: serializer.fromJson<String>(json['sourceEpisodeId']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      bytes: serializer.fromJson<int?>(json['bytes']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      downloadedAt: serializer.fromJson<DateTime?>(json['downloadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceEpisodeId': serializer.toJson<String>(sourceEpisodeId),
      'filePath': serializer.toJson<String?>(filePath),
      'bytes': serializer.toJson<int?>(bytes),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'downloadedAt': serializer.toJson<DateTime?>(downloadedAt),
    };
  }

  DownloadRow copyWith({
    int? id,
    String? sourceType,
    String? sourceEpisodeId,
    Value<String?> filePath = const Value.absent(),
    Value<int?> bytes = const Value.absent(),
    String? status,
    Value<String?> errorMessage = const Value.absent(),
    Value<DateTime?> downloadedAt = const Value.absent(),
  }) => DownloadRow(
    id: id ?? this.id,
    sourceType: sourceType ?? this.sourceType,
    sourceEpisodeId: sourceEpisodeId ?? this.sourceEpisodeId,
    filePath: filePath.present ? filePath.value : this.filePath,
    bytes: bytes.present ? bytes.value : this.bytes,
    status: status ?? this.status,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    downloadedAt: downloadedAt.present ? downloadedAt.value : this.downloadedAt,
  );
  DownloadRow copyWithCompanion(DownloadsTableCompanion data) {
    return DownloadRow(
      id: data.id.present ? data.id.value : this.id,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceEpisodeId: data.sourceEpisodeId.present
          ? data.sourceEpisodeId.value
          : this.sourceEpisodeId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadRow(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceEpisodeId: $sourceEpisodeId, ')
          ..write('filePath: $filePath, ')
          ..write('bytes: $bytes, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceType,
    sourceEpisodeId,
    filePath,
    bytes,
    status,
    errorMessage,
    downloadedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadRow &&
          other.id == this.id &&
          other.sourceType == this.sourceType &&
          other.sourceEpisodeId == this.sourceEpisodeId &&
          other.filePath == this.filePath &&
          other.bytes == this.bytes &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage &&
          other.downloadedAt == this.downloadedAt);
}

class DownloadsTableCompanion extends UpdateCompanion<DownloadRow> {
  final Value<int> id;
  final Value<String> sourceType;
  final Value<String> sourceEpisodeId;
  final Value<String?> filePath;
  final Value<int?> bytes;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<DateTime?> downloadedAt;
  const DownloadsTableCompanion({
    this.id = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceEpisodeId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.bytes = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.downloadedAt = const Value.absent(),
  });
  DownloadsTableCompanion.insert({
    this.id = const Value.absent(),
    required String sourceType,
    required String sourceEpisodeId,
    this.filePath = const Value.absent(),
    this.bytes = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.downloadedAt = const Value.absent(),
  }) : sourceType = Value(sourceType),
       sourceEpisodeId = Value(sourceEpisodeId);
  static Insertable<DownloadRow> custom({
    Expression<int>? id,
    Expression<String>? sourceType,
    Expression<String>? sourceEpisodeId,
    Expression<String>? filePath,
    Expression<int>? bytes,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<DateTime>? downloadedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceEpisodeId != null) 'source_episode_id': sourceEpisodeId,
      if (filePath != null) 'file_path': filePath,
      if (bytes != null) 'bytes': bytes,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
    });
  }

  DownloadsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? sourceType,
    Value<String>? sourceEpisodeId,
    Value<String?>? filePath,
    Value<int?>? bytes,
    Value<String>? status,
    Value<String?>? errorMessage,
    Value<DateTime?>? downloadedAt,
  }) {
    return DownloadsTableCompanion(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      sourceEpisodeId: sourceEpisodeId ?? this.sourceEpisodeId,
      filePath: filePath ?? this.filePath,
      bytes: bytes ?? this.bytes,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      downloadedAt: downloadedAt ?? this.downloadedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceEpisodeId.present) {
      map['source_episode_id'] = Variable<String>(sourceEpisodeId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsTableCompanion(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceEpisodeId: $sourceEpisodeId, ')
          ..write('filePath: $filePath, ')
          ..write('bytes: $bytes, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SeriesTableTable seriesTable = $SeriesTableTable(this);
  late final $EpisodesTableTable episodesTable = $EpisodesTableTable(this);
  late final $DownloadsTableTable downloadsTable = $DownloadsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    seriesTable,
    episodesTable,
    downloadsTable,
  ];
}

typedef $$SeriesTableTableCreateCompanionBuilder =
    SeriesTableCompanion Function({
      Value<int> id,
      required String sourceType,
      required String seriesKind,
      required String sourceSeriesId,
      required int sortOrder,
      required String title,
      Value<String?> author,
      Value<String?> description,
      Value<String?> imageUrl,
      Value<String?> originalUrl,
      Value<String?> feedUrl,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$SeriesTableTableUpdateCompanionBuilder =
    SeriesTableCompanion Function({
      Value<int> id,
      Value<String> sourceType,
      Value<String> seriesKind,
      Value<String> sourceSeriesId,
      Value<int> sortOrder,
      Value<String> title,
      Value<String?> author,
      Value<String?> description,
      Value<String?> imageUrl,
      Value<String?> originalUrl,
      Value<String?> feedUrl,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$SeriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesKind => $composableBuilder(
    column: $table.seriesKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceSeriesId => $composableBuilder(
    column: $table.sourceSeriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalUrl => $composableBuilder(
    column: $table.originalUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feedUrl => $composableBuilder(
    column: $table.feedUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SeriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesKind => $composableBuilder(
    column: $table.seriesKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceSeriesId => $composableBuilder(
    column: $table.sourceSeriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalUrl => $composableBuilder(
    column: $table.originalUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedUrl => $composableBuilder(
    column: $table.feedUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seriesKind => $composableBuilder(
    column: $table.seriesKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceSeriesId => $composableBuilder(
    column: $table.sourceSeriesId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get originalUrl => $composableBuilder(
    column: $table.originalUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get feedUrl =>
      $composableBuilder(column: $table.feedUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SeriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeriesTableTable,
          SeriesRow,
          $$SeriesTableTableFilterComposer,
          $$SeriesTableTableOrderingComposer,
          $$SeriesTableTableAnnotationComposer,
          $$SeriesTableTableCreateCompanionBuilder,
          $$SeriesTableTableUpdateCompanionBuilder,
          (
            SeriesRow,
            BaseReferences<_$AppDatabase, $SeriesTableTable, SeriesRow>,
          ),
          SeriesRow,
          PrefetchHooks Function()
        > {
  $$SeriesTableTableTableManager(_$AppDatabase db, $SeriesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeriesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> seriesKind = const Value.absent(),
                Value<String> sourceSeriesId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> originalUrl = const Value.absent(),
                Value<String?> feedUrl = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SeriesTableCompanion(
                id: id,
                sourceType: sourceType,
                seriesKind: seriesKind,
                sourceSeriesId: sourceSeriesId,
                sortOrder: sortOrder,
                title: title,
                author: author,
                description: description,
                imageUrl: imageUrl,
                originalUrl: originalUrl,
                feedUrl: feedUrl,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sourceType,
                required String seriesKind,
                required String sourceSeriesId,
                required int sortOrder,
                required String title,
                Value<String?> author = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> originalUrl = const Value.absent(),
                Value<String?> feedUrl = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => SeriesTableCompanion.insert(
                id: id,
                sourceType: sourceType,
                seriesKind: seriesKind,
                sourceSeriesId: sourceSeriesId,
                sortOrder: sortOrder,
                title: title,
                author: author,
                description: description,
                imageUrl: imageUrl,
                originalUrl: originalUrl,
                feedUrl: feedUrl,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SeriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeriesTableTable,
      SeriesRow,
      $$SeriesTableTableFilterComposer,
      $$SeriesTableTableOrderingComposer,
      $$SeriesTableTableAnnotationComposer,
      $$SeriesTableTableCreateCompanionBuilder,
      $$SeriesTableTableUpdateCompanionBuilder,
      (SeriesRow, BaseReferences<_$AppDatabase, $SeriesTableTable, SeriesRow>),
      SeriesRow,
      PrefetchHooks Function()
    >;
typedef $$EpisodesTableTableCreateCompanionBuilder =
    EpisodesTableCompanion Function({
      Value<int> id,
      Value<int?> seriesId,
      required String sourceType,
      required String sourceEpisodeId,
      required int sortOrder,
      required String title,
      Value<String?> author,
      Value<String?> description,
      Value<String?> imageUrl,
      Value<String?> originalUrl,
      Value<String?> audioUrl,
      Value<String?> videoUrl,
      Value<int?> durationMs,
      Value<int?> audioBytes,
      Value<DateTime?> publishedAt,
      Value<String?> bilibiliBvid,
      Value<int?> bilibiliAid,
      Value<int?> bilibiliCid,
      Value<int?> bilibiliPage,
      Value<int> progressMs,
      Value<DateTime?> lastPlayedAt,
      Value<bool> isCompleted,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$EpisodesTableTableUpdateCompanionBuilder =
    EpisodesTableCompanion Function({
      Value<int> id,
      Value<int?> seriesId,
      Value<String> sourceType,
      Value<String> sourceEpisodeId,
      Value<int> sortOrder,
      Value<String> title,
      Value<String?> author,
      Value<String?> description,
      Value<String?> imageUrl,
      Value<String?> originalUrl,
      Value<String?> audioUrl,
      Value<String?> videoUrl,
      Value<int?> durationMs,
      Value<int?> audioBytes,
      Value<DateTime?> publishedAt,
      Value<String?> bilibiliBvid,
      Value<int?> bilibiliAid,
      Value<int?> bilibiliCid,
      Value<int?> bilibiliPage,
      Value<int> progressMs,
      Value<DateTime?> lastPlayedAt,
      Value<bool> isCompleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$EpisodesTableTableFilterComposer
    extends Composer<_$AppDatabase, $EpisodesTableTable> {
  $$EpisodesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceEpisodeId => $composableBuilder(
    column: $table.sourceEpisodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalUrl => $composableBuilder(
    column: $table.originalUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get audioBytes => $composableBuilder(
    column: $table.audioBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bilibiliBvid => $composableBuilder(
    column: $table.bilibiliBvid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bilibiliAid => $composableBuilder(
    column: $table.bilibiliAid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bilibiliCid => $composableBuilder(
    column: $table.bilibiliCid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bilibiliPage => $composableBuilder(
    column: $table.bilibiliPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progressMs => $composableBuilder(
    column: $table.progressMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EpisodesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $EpisodesTableTable> {
  $$EpisodesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceEpisodeId => $composableBuilder(
    column: $table.sourceEpisodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalUrl => $composableBuilder(
    column: $table.originalUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get audioBytes => $composableBuilder(
    column: $table.audioBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bilibiliBvid => $composableBuilder(
    column: $table.bilibiliBvid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bilibiliAid => $composableBuilder(
    column: $table.bilibiliAid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bilibiliCid => $composableBuilder(
    column: $table.bilibiliCid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bilibiliPage => $composableBuilder(
    column: $table.bilibiliPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progressMs => $composableBuilder(
    column: $table.progressMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EpisodesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpisodesTableTable> {
  $$EpisodesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceEpisodeId => $composableBuilder(
    column: $table.sourceEpisodeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get originalUrl => $composableBuilder(
    column: $table.originalUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioUrl =>
      $composableBuilder(column: $table.audioUrl, builder: (column) => column);

  GeneratedColumn<String> get videoUrl =>
      $composableBuilder(column: $table.videoUrl, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get audioBytes => $composableBuilder(
    column: $table.audioBytes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bilibiliBvid => $composableBuilder(
    column: $table.bilibiliBvid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bilibiliAid => $composableBuilder(
    column: $table.bilibiliAid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bilibiliCid => $composableBuilder(
    column: $table.bilibiliCid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bilibiliPage => $composableBuilder(
    column: $table.bilibiliPage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get progressMs => $composableBuilder(
    column: $table.progressMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EpisodesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpisodesTableTable,
          EpisodeRow,
          $$EpisodesTableTableFilterComposer,
          $$EpisodesTableTableOrderingComposer,
          $$EpisodesTableTableAnnotationComposer,
          $$EpisodesTableTableCreateCompanionBuilder,
          $$EpisodesTableTableUpdateCompanionBuilder,
          (
            EpisodeRow,
            BaseReferences<_$AppDatabase, $EpisodesTableTable, EpisodeRow>,
          ),
          EpisodeRow,
          PrefetchHooks Function()
        > {
  $$EpisodesTableTableTableManager(_$AppDatabase db, $EpisodesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpisodesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> seriesId = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> sourceEpisodeId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> originalUrl = const Value.absent(),
                Value<String?> audioUrl = const Value.absent(),
                Value<String?> videoUrl = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int?> audioBytes = const Value.absent(),
                Value<DateTime?> publishedAt = const Value.absent(),
                Value<String?> bilibiliBvid = const Value.absent(),
                Value<int?> bilibiliAid = const Value.absent(),
                Value<int?> bilibiliCid = const Value.absent(),
                Value<int?> bilibiliPage = const Value.absent(),
                Value<int> progressMs = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => EpisodesTableCompanion(
                id: id,
                seriesId: seriesId,
                sourceType: sourceType,
                sourceEpisodeId: sourceEpisodeId,
                sortOrder: sortOrder,
                title: title,
                author: author,
                description: description,
                imageUrl: imageUrl,
                originalUrl: originalUrl,
                audioUrl: audioUrl,
                videoUrl: videoUrl,
                durationMs: durationMs,
                audioBytes: audioBytes,
                publishedAt: publishedAt,
                bilibiliBvid: bilibiliBvid,
                bilibiliAid: bilibiliAid,
                bilibiliCid: bilibiliCid,
                bilibiliPage: bilibiliPage,
                progressMs: progressMs,
                lastPlayedAt: lastPlayedAt,
                isCompleted: isCompleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> seriesId = const Value.absent(),
                required String sourceType,
                required String sourceEpisodeId,
                required int sortOrder,
                required String title,
                Value<String?> author = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> originalUrl = const Value.absent(),
                Value<String?> audioUrl = const Value.absent(),
                Value<String?> videoUrl = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int?> audioBytes = const Value.absent(),
                Value<DateTime?> publishedAt = const Value.absent(),
                Value<String?> bilibiliBvid = const Value.absent(),
                Value<int?> bilibiliAid = const Value.absent(),
                Value<int?> bilibiliCid = const Value.absent(),
                Value<int?> bilibiliPage = const Value.absent(),
                Value<int> progressMs = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => EpisodesTableCompanion.insert(
                id: id,
                seriesId: seriesId,
                sourceType: sourceType,
                sourceEpisodeId: sourceEpisodeId,
                sortOrder: sortOrder,
                title: title,
                author: author,
                description: description,
                imageUrl: imageUrl,
                originalUrl: originalUrl,
                audioUrl: audioUrl,
                videoUrl: videoUrl,
                durationMs: durationMs,
                audioBytes: audioBytes,
                publishedAt: publishedAt,
                bilibiliBvid: bilibiliBvid,
                bilibiliAid: bilibiliAid,
                bilibiliCid: bilibiliCid,
                bilibiliPage: bilibiliPage,
                progressMs: progressMs,
                lastPlayedAt: lastPlayedAt,
                isCompleted: isCompleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EpisodesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpisodesTableTable,
      EpisodeRow,
      $$EpisodesTableTableFilterComposer,
      $$EpisodesTableTableOrderingComposer,
      $$EpisodesTableTableAnnotationComposer,
      $$EpisodesTableTableCreateCompanionBuilder,
      $$EpisodesTableTableUpdateCompanionBuilder,
      (
        EpisodeRow,
        BaseReferences<_$AppDatabase, $EpisodesTableTable, EpisodeRow>,
      ),
      EpisodeRow,
      PrefetchHooks Function()
    >;
typedef $$DownloadsTableTableCreateCompanionBuilder =
    DownloadsTableCompanion Function({
      Value<int> id,
      required String sourceType,
      required String sourceEpisodeId,
      Value<String?> filePath,
      Value<int?> bytes,
      Value<String> status,
      Value<String?> errorMessage,
      Value<DateTime?> downloadedAt,
    });
typedef $$DownloadsTableTableUpdateCompanionBuilder =
    DownloadsTableCompanion Function({
      Value<int> id,
      Value<String> sourceType,
      Value<String> sourceEpisodeId,
      Value<String?> filePath,
      Value<int?> bytes,
      Value<String> status,
      Value<String?> errorMessage,
      Value<DateTime?> downloadedAt,
    });

class $$DownloadsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadsTableTable> {
  $$DownloadsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceEpisodeId => $composableBuilder(
    column: $table.sourceEpisodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadsTableTable> {
  $$DownloadsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceEpisodeId => $composableBuilder(
    column: $table.sourceEpisodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadsTableTable> {
  $$DownloadsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceEpisodeId => $composableBuilder(
    column: $table.sourceEpisodeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );
}

class $$DownloadsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadsTableTable,
          DownloadRow,
          $$DownloadsTableTableFilterComposer,
          $$DownloadsTableTableOrderingComposer,
          $$DownloadsTableTableAnnotationComposer,
          $$DownloadsTableTableCreateCompanionBuilder,
          $$DownloadsTableTableUpdateCompanionBuilder,
          (
            DownloadRow,
            BaseReferences<_$AppDatabase, $DownloadsTableTable, DownloadRow>,
          ),
          DownloadRow,
          PrefetchHooks Function()
        > {
  $$DownloadsTableTableTableManager(
    _$AppDatabase db,
    $DownloadsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> sourceEpisodeId = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<int?> bytes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<DateTime?> downloadedAt = const Value.absent(),
              }) => DownloadsTableCompanion(
                id: id,
                sourceType: sourceType,
                sourceEpisodeId: sourceEpisodeId,
                filePath: filePath,
                bytes: bytes,
                status: status,
                errorMessage: errorMessage,
                downloadedAt: downloadedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sourceType,
                required String sourceEpisodeId,
                Value<String?> filePath = const Value.absent(),
                Value<int?> bytes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<DateTime?> downloadedAt = const Value.absent(),
              }) => DownloadsTableCompanion.insert(
                id: id,
                sourceType: sourceType,
                sourceEpisodeId: sourceEpisodeId,
                filePath: filePath,
                bytes: bytes,
                status: status,
                errorMessage: errorMessage,
                downloadedAt: downloadedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadsTableTable,
      DownloadRow,
      $$DownloadsTableTableFilterComposer,
      $$DownloadsTableTableOrderingComposer,
      $$DownloadsTableTableAnnotationComposer,
      $$DownloadsTableTableCreateCompanionBuilder,
      $$DownloadsTableTableUpdateCompanionBuilder,
      (
        DownloadRow,
        BaseReferences<_$AppDatabase, $DownloadsTableTable, DownloadRow>,
      ),
      DownloadRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SeriesTableTableTableManager get seriesTable =>
      $$SeriesTableTableTableManager(_db, _db.seriesTable);
  $$EpisodesTableTableTableManager get episodesTable =>
      $$EpisodesTableTableTableManager(_db, _db.episodesTable);
  $$DownloadsTableTableTableManager get downloadsTable =>
      $$DownloadsTableTableTableManager(_db, _db.downloadsTable);
}
