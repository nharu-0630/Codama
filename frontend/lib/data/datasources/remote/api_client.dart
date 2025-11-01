import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../domain/entities/location_data.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: 'http://localhost:8000')
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  @POST('/signup')
  Future<AuthResponse> signup();

  @POST('/signin')
  Future<AuthResponse> signin(@Body() SigninRequest request);

  @POST('/refresh')
  Future<AuthResponse> refresh(@Body() RefreshRequest request);

  @GET('/posts')
  Future<PostsResponse> getPosts(
    @Query('lat') double lat,
    @Query('lon') double lon,
  );

  @POST('/posts')
  Future<CreatePostResponse> createPost(@Body() CreatePostRequest request);

  @GET('/areas/{lat}/{lon}')
  Future<AreaResponse> getCurrentLocation(
    @Path('lat') double lat,
    @Path('lon') double lon,
  );
}

// Request/Response Models
class SigninRequest {
  final String username;
  final String password;

  SigninRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

class RefreshRequest {
  final String refreshToken;

  RefreshRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refresh_token': refreshToken};
}

class CreatePostRequest {
  final String content;
  final double lat;
  final double lon;

  CreatePostRequest({
    required this.content,
    required this.lat,
    required this.lon,
  });

  Map<String, dynamic> toJson() => {'content': content, 'lat': lat, 'lon': lon};
}

class UserResponse {
  final String id;
  final String? email;
  final String createdAt;

  UserResponse({required this.id, this.email, required this.createdAt});

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
    id: json['user_id'] ?? '',
    email: json['email'],
    createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
  );
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String userId;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken: json['access_token'] ?? '',
    refreshToken: json['refresh_token'] ?? '',
    userId: json['user_id'] ?? '',
  );
}

class PostsResponse {
  final List<Map<String, dynamic>> posts;

  PostsResponse({required this.posts});

  factory PostsResponse.fromJson(Map<String, dynamic> json) => PostsResponse(
    posts: List<Map<String, dynamic>>.from(
      json['posts']?.map((x) => Map<String, dynamic>.from(x)) ?? [],
    ),
  );
}

class CreatePostResponse {
  final Map<String, dynamic> post;
  final List<dynamic> similarPosts;

  CreatePostResponse({required this.post, required this.similarPosts});

  factory CreatePostResponse.fromJson(Map<String, dynamic> json) =>
      CreatePostResponse(
        post: Map<String, dynamic>.from(json['post'] ?? {}),
        similarPosts: List<dynamic>.from(json['similar_posts'] ?? []),
      );
}

class AreaResponse {
  final Area area;
  final Cell cell;

  AreaResponse({required this.area, required this.cell});

  factory AreaResponse.fromJson(Map<String, dynamic> json) => AreaResponse(
    area: Area.fromJson(json['area'] ?? {}),
    cell: Cell.fromJson(json['cell'] ?? {}),
  );
}
