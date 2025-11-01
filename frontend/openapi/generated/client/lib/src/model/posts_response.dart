//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:openapi/src/model/api_post_output.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'posts_response.g.dart';

/// 投稿一覧エンドポイントのレスポンス
///
/// Properties:
/// * [posts] 
@BuiltValue()
abstract class PostsResponse implements Built<PostsResponse, PostsResponseBuilder> {
  @BuiltValueField(wireName: r'posts')
  BuiltList<APIPostOutput> get posts;

  PostsResponse._();

  factory PostsResponse([void updates(PostsResponseBuilder b)]) = _$PostsResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PostsResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PostsResponse> get serializer => _$PostsResponseSerializer();
}

class _$PostsResponseSerializer implements PrimitiveSerializer<PostsResponse> {
  @override
  final Iterable<Type> types = const [PostsResponse, _$PostsResponse];

  @override
  final String wireName = r'PostsResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PostsResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'posts';
    yield serializers.serialize(
      object.posts,
      specifiedType: const FullType(BuiltList, [FullType(APIPostOutput)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PostsResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PostsResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'posts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(APIPostOutput)]),
          ) as BuiltList<APIPostOutput>;
          result.posts.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PostsResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PostsResponseBuilder();
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

