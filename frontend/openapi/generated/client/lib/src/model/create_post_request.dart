//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_post_request.g.dart';

/// 投稿作成エンドポイントのリクエスト
///
/// Properties:
/// * [content] 
/// * [lat] 
/// * [lon] 
@BuiltValue()
abstract class CreatePostRequest implements Built<CreatePostRequest, CreatePostRequestBuilder> {
  @BuiltValueField(wireName: r'content')
  String get content;

  @BuiltValueField(wireName: r'lat')
  num get lat;

  @BuiltValueField(wireName: r'lon')
  num get lon;

  CreatePostRequest._();

  factory CreatePostRequest([void updates(CreatePostRequestBuilder b)]) = _$CreatePostRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreatePostRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreatePostRequest> get serializer => _$CreatePostRequestSerializer();
}

class _$CreatePostRequestSerializer implements PrimitiveSerializer<CreatePostRequest> {
  @override
  final Iterable<Type> types = const [CreatePostRequest, _$CreatePostRequest];

  @override
  final String wireName = r'CreatePostRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreatePostRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'content';
    yield serializers.serialize(
      object.content,
      specifiedType: const FullType(String),
    );
    yield r'lat';
    yield serializers.serialize(
      object.lat,
      specifiedType: const FullType(num),
    );
    yield r'lon';
    yield serializers.serialize(
      object.lon,
      specifiedType: const FullType(num),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreatePostRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreatePostRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'content':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.content = valueDes;
          break;
        case r'lat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.lat = valueDes;
          break;
        case r'lon':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.lon = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreatePostRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreatePostRequestBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

