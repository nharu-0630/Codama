// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostImpl _$$PostImplFromJson(Map<String, dynamic> json) => _$PostImpl(
  id: json['id'] as String,
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  kind: $enumDecode(_$PostKindEnumMap, json['kind']),
  text: json['text'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  userId: json['userId'] as String,
  isTemporary: json['isTemporary'] as bool? ?? false,
  replies:
      (json['replies'] as List<dynamic>?)
          ?.map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$PostImplToJson(_$PostImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lat': instance.lat,
      'lng': instance.lng,
      'kind': _$PostKindEnumMap[instance.kind]!,
      'text': instance.text,
      'createdAt': instance.createdAt.toIso8601String(),
      'userId': instance.userId,
      'isTemporary': instance.isTemporary,
      'replies': instance.replies,
    };

const _$PostKindEnumMap = {PostKind.user: 'user', PostKind.land: 'land'};
