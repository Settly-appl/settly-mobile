import 'dart:convert';

import 'package:settly_mobile/models/project.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';

/// Wraps the /projects endpoints (CRUD + membership).
class ProjectsService {
  final ApiServiceRequest _api = ApiServiceRequest();

  Future<List<Project>> getMyProjects() async {
    final res = await _api.request(endpoint: 'projects', method: HttpMethod.get);
    if (res != null && res.statusCode == 200) {
      return Project.listFromJson(jsonDecode(res.body) as List<dynamic>);
    }
    throw Exception('Nie udało się pobrać projektów');
  }

  Future<Project> getProject(String projectId) async {
    final res = await _api.request(
      endpoint: 'projects/$projectId',
      method: HttpMethod.get,
    );
    if (res != null && res.statusCode == 200) {
      return Project.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Nie udało się pobrać projektu');
  }

  Future<Project> createProject({
    required String name,
    String? description,
  }) async {
    final res = await _api.request(
      endpoint: 'projects',
      method: HttpMethod.post,
      body: {'name': name, 'description': ?description},
    );
    if (res != null && (res.statusCode == 200 || res.statusCode == 201)) {
      return Project.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Nie udało się utworzyć projektu');
  }

  Future<Project> updateProject(
    String projectId, {
    String? name,
    String? description,
    String? status,
  }) async {
    final res = await _api.request(
      endpoint: 'projects/$projectId',
      method: HttpMethod.patch,
      body: {'name': ?name, 'description': ?description, 'status': ?status},
    );
    if (res != null && res.statusCode == 200) {
      return Project.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Nie udało się zaktualizować projektu');
  }

  Future<void> deleteProject(String projectId) async {
    final res = await _api.request(
      endpoint: 'projects/$projectId',
      method: HttpMethod.delete,
    );
    if (res == null || (res.statusCode != 200 && res.statusCode != 204)) {
      throw Exception('Nie udało się usunąć projektu');
    }
  }

  Future<List<ProjectMember>> getMembers(String projectId) async {
    final res = await _api.request(
      endpoint: 'projects/$projectId/members',
      method: HttpMethod.get,
    );
    if (res != null && res.statusCode == 200) {
      return ProjectMember.listFromJson(jsonDecode(res.body) as List<dynamic>);
    }
    throw Exception('Nie udało się pobrać uczestników');
  }

  Future<void> addMember(String projectId, String userId) async {
    final res = await _api.request(
      endpoint: 'projects/$projectId/members',
      method: HttpMethod.post,
      body: {'userId': userId},
    );
    if (res == null || (res.statusCode != 200 && res.statusCode != 201)) {
      throw Exception('Nie udało się dodać uczestnika');
    }
  }

  Future<void> removeMember(String projectId, String memberUserId) async {
    final res = await _api.request(
      endpoint: 'projects/$projectId/members/$memberUserId',
      method: HttpMethod.delete,
    );
    if (res == null || (res.statusCode != 200 && res.statusCode != 204)) {
      throw Exception('Nie udało się usunąć uczestnika');
    }
  }

  Future<void> leaveProject(String projectId) async {
    final res = await _api.request(
      endpoint: 'projects/$projectId/members/me',
      method: HttpMethod.delete,
    );
    if (res == null || (res.statusCode != 200 && res.statusCode != 204)) {
      throw Exception('Nie udało się opuścić projektu');
    }
  }
}
