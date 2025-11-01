//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:openapi/src/model/api_post_output.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_post_response.g.dart';

/// 投稿作成エンドポイントのレスポンス
///
/// Properties:
/// * [post] 
/// * [similarPosts] 
@BuiltValue()
abstract class CreatePostResponse implements Built<CreatePostResponse, CreatePostResponseBuilder> {
  @BuiltValueField(wireName: r'post')
  APIPostOutput get post;

  @BuiltValueField(wireName: r'similar_posts')
  BuiltList<APIPostOutput> get similarPosts;

  CreatePostResponse._();

  factory CreatePostResponse([void updates(CreatePostResponseBuilder b)]) = _$CreatePostResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreatePostResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreatePostResponse> get serializer => _$CreatePostResponseSerializer();
}

class _$CreatePostResponseSerializer implements PrimitiveSerializer<CreatePostResponse> {
  @override
  final Iterable<Type> types = const [CreatePostResponse, _$CreatePostResponse];

  @override
  final String wireName = r'CreatePostResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreatePostResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'post';
    yield serializers.serialize(
      object.post,
      specifiedType: const FullType(APIPostOutput),
    );
    yield r'similar_posts';
    yield serializers.serialize(
      object.similarPosts,
      specifiedType: const FullType(BuiltList, [FullType(APIPostOutput)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreatePostResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreatePostResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'post':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(APIPostOutput),
          ) as APIPostOutput;
          result.post.replace(valueDes);
          break;
        case r'similar_posts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(APIPostOutput)]),
          ) as BuiltList<APIPostOutput>;
          result.similarPosts.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreatePostResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreatePostResponseBuilder();
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

