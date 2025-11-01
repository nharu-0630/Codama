//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_prompt_response.g.dart';

/// プロンプト更新エンドポイントのレスポンス
///
/// Properties:
/// * [success] 
@BuiltValue()
abstract class UpdatePromptResponse implements Built<UpdatePromptResponse, UpdatePromptResponseBuilder> {
  @BuiltValueField(wireName: r'success')
  bool get success;

  UpdatePromptResponse._();

  factory UpdatePromptResponse([void updates(UpdatePromptResponseBuilder b)]) = _$UpdatePromptResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdatePromptResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdatePromptResponse> get serializer => _$UpdatePromptResponseSerializer();
}

class _$UpdatePromptResponseSerializer implements PrimitiveSerializer<UpdatePromptResponse> {
  @override
  final Iterable<Type> types = const [UpdatePromptResponse, _$UpdatePromptResponse];

  @override
  final String wireName = r'UpdatePromptResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdatePromptResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'success';
    yield serializers.serialize(
      object.success,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdatePromptResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdatePromptResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'success':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.success = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdatePromptResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdatePromptResponseBuilder();
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

