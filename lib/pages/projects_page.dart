import 'package:flutter/material.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/models/project.dart';
import 'package:settly_mobile/pages/project_detail_page.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/api_service/projects_service.dart';

/// Lists the projects (groups) the current user belongs to and lets them
/// create a new one.
class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final _service = ProjectsService();

  bool _loading = true;
  String? _error;
  List<Project> _projects = [];

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getMyProjects();
      if (!mounted) return;
      setState(() {
        _projects = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Nie udało się pobrać projektów. Spróbuj ponownie.';
        _loading = false;
      });
    }
  }

  Future<void> _openCreateSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.scaffold(isDark),
      builder: (_) => _CreateProjectSheet(isDark: isDark, service: _service),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    return Scaffold(
      backgroundColor: AppColors.scaffold(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          texts.projectsTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.username(isDark),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet,
        backgroundColor: AppColors.avatarFg(isDark),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          texts.projectNewProject,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(onRefresh: _load, child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    final texts = AppTexts.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _centered(
        Icons.cloud_off_rounded,
        _error!,
        action: OutlinedButton(
          onPressed: _load,
          child: Text(texts.retryAction),
        ),
      );
    }
    if (_projects.isEmpty) {
      return _centered(
        Icons.groups_2_outlined,
        texts.noProjects,
        subtitle: texts.projectNoProjectsHint,
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: _projects.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _ProjectCard(
        project: _projects[i],
        isDark: isDark,
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProjectDetailPage(projectId: _projects[i].id),
            ),
          );
          _load();
        },
      ),
    );
  }

  Widget _centered(
    IconData icon,
    String title, {
    String? subtitle,
    Widget? action,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
          child: Column(
            children: [
              Icon(icon, size: 56, color: AppColors.cardSubtitle(isDark)),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cardTitle(isDark),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.cardSubtitle(isDark),
                  ),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 16), action],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final bool isDark;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder(isDark)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.actionProjectIconBg(isDark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.groups_2_outlined,
                color: AppColors.actionProjectIcon(isDark),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cardTitle(isDark),
                          ),
                        ),
                      ),
                      if (project.isSettled) _StatusChip(isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${project.memberCount} '
                    '${project.memberCount == 1 ? texts.projectMembersCountSuffixSingular : texts.projectMembersCountSuffixPlural}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.cardSubtitle(isDark),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.cardSubtitle(isDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isDark;
  const _StatusChip({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.amountPositive.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texts.projectSettledStatus,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.amountPositive,
        ),
      ),
    );
  }
}

class _CreateProjectSheet extends StatefulWidget {
  final bool isDark;
  final ProjectsService service;

  const _CreateProjectSheet({required this.isDark, required this.service});

  @override
  State<_CreateProjectSheet> createState() => _CreateProjectSheetState();
}

class _CreateProjectSheetState extends State<_CreateProjectSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.service.createProject(
        name: name,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTexts.of(context).projectCreateFailedError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppTexts.of(context).projectNewProject,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.username(widget.isDark),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: texts.projectNameLabel,
              hintText: texts.projectNameExample,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: texts.projectDescriptionLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.avatarFg(widget.isDark),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    AppTexts.of(context).createAction,
                    style: const TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}
