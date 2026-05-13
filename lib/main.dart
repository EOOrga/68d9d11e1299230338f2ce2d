import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bool kScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');
const String appName = 'BORDEAUX ELISABETH';
const String supportEmail = 'support@bordeauxelisabeth.com';

void main() {
  runApp(const BordeauxApp(screenshotMode: kScreenshotMode));
}

class BordeauxApp extends StatelessWidget {
  const BordeauxApp({super.key, required this.screenshotMode});

  final bool screenshotMode;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF183869);
    const secondary = Color(0xFF0F766E);
    const tertiary = Color(0xFFC97719);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      surface: const Color(0xFFF7F8FB),
    );

    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFFF4F6FA),
          foregroundColor: primary,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE0E6EF)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: secondary.withAlpha(32),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: AppLoader(store: LocalStore(screenshotMode: screenshotMode)),
    );
  }
}

class AppLoader extends StatefulWidget {
  const AppLoader({super.key, required this.store});

  final LocalStore store;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  late final Future<OpsData> _future = widget.store.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OpsData>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return OperationsShell(
          initialData: snapshot.data!,
          store: widget.store,
        );
      },
    );
  }
}

class OperationsShell extends StatefulWidget {
  const OperationsShell({
    super.key,
    required this.initialData,
    required this.store,
  });

  final OpsData initialData;
  final LocalStore store;

  @override
  State<OperationsShell> createState() => _OperationsShellState();
}

class _OperationsShellState extends State<OperationsShell> {
  late OpsData data = widget.initialData;
  int index = 0;

  void updateData(OpsData next) {
    setState(() => data = next);
    widget.store.save(next);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(data: data, onChanged: updateData),
      LeadsScreen(data: data, onChanged: updateData),
      TrainingScreen(data: data, onChanged: updateData),
      VisitorsScreen(data: data, onChanged: updateData),
      SettingsScreen(data: data, onChanged: updateData),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          appName,
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: const Icon(Icons.verified_user_outlined, size: 16),
              label: const Text('Local'),
              side: BorderSide.none,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.secondary.withAlpha(28),
            ),
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.handshake_outlined),
            selectedIcon: Icon(Icons.handshake),
            label: 'Leads',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Training',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge),
            label: 'Visitors',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final OpsData data;
  final ValueChanged<OpsData> onChanged;

  @override
  Widget build(BuildContext context) {
    final activeLeads = data.leads.where((lead) => lead.stage != 'Won').length;
    final checkedVisitors = data.visitors
        .where((visitor) => visitor.status == 'Checked in')
        .length;
    final averageTraining = data.courses.isEmpty
        ? 0
        : (data.courses
                      .map((course) => course.progress)
                      .reduce((a, b) => a + b) /
                  data.courses.length)
              .round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SectionHeader(
          title: 'Operations board',
          action: FilledButton.icon(
            key: const Key('new-allocation'),
            onPressed: () => _showResourceDialog(context),
            icon: const Icon(Icons.add_chart),
            label: const Text('New allocation'),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.55,
          children: [
            MetricCard(
              label: 'Resource plans',
              value: '${data.resources.length}',
              icon: Icons.inventory_2_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            MetricCard(
              label: 'Open leads',
              value: '$activeLeads',
              icon: Icons.trending_up,
              color: Theme.of(context).colorScheme.secondary,
            ),
            MetricCard(
              label: 'Training',
              value: '$averageTraining%',
              icon: Icons.school_outlined,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            MetricCard(
              label: 'Visitors in',
              value: '$checkedVisitors',
              icon: Icons.login_outlined,
              color: const Color(0xFF4F6F52),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Resource allocation',
          subtitle: 'Live plans by team and owner',
        ),
        const SizedBox(height: 8),
        ...data.resources.map((plan) => ResourcePlanCard(plan: plan)),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Today focus',
          subtitle: 'Local reminders for the daily standup',
        ),
        const SizedBox(height: 8),
        FocusItem(
          icon: Icons.route_outlined,
          title: 'Confirm visitor flow',
          detail:
              '${data.visitors.length} scheduled entries need host coverage.',
        ),
        FocusItem(
          icon: Icons.assignment_turned_in_outlined,
          title: 'Review training gaps',
          detail: 'Keep course progress above 80% for front desk coverage.',
        ),
        FocusItem(
          icon: Icons.request_quote_outlined,
          title: 'Lead follow-up',
          detail: 'Prioritize next steps with a clear owner before close.',
        ),
      ],
    );
  }

  Future<void> _showResourceDialog(BuildContext context) async {
    final plan = await showDialog<ResourcePlan>(
      context: context,
      builder: (context) => const ResourceDialog(),
    );

    if (plan == null) return;
    onChanged(data.copyWith(resources: [plan, ...data.resources]));
  }
}

class LeadsScreen extends StatelessWidget {
  const LeadsScreen({super.key, required this.data, required this.onChanged});

  final OpsData data;
  final ValueChanged<OpsData> onChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-lead'),
        onPressed: () => _showLeadDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add lead'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          const SectionHeader(
            title: 'Lead management',
            subtitle: 'Track owners, stages, value, and next action',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              StatusPill(label: 'Qualified', color: Color(0xFF183869)),
              StatusPill(label: 'Proposal', color: Color(0xFF0F766E)),
              StatusPill(label: 'Won', color: Color(0xFF4F6F52)),
            ],
          ),
          const SizedBox(height: 12),
          ...data.leads.map(
            (lead) => LeadCard(
              lead: lead,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => LeadDetailScreen(lead: lead)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLeadDialog(BuildContext context) async {
    final lead = await showDialog<LeadRecord>(
      context: context,
      builder: (context) => const LeadDialog(),
    );

    if (lead == null) return;
    onChanged(data.copyWith(leads: [lead, ...data.leads]));
  }
}

class LeadDetailScreen extends StatelessWidget {
  const LeadDetailScreen({super.key, required this.lead});

  final LeadRecord lead;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lead.company)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.stage,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lead.company,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Owner: ${lead.owner}'),
                  Text('Estimated value: ${lead.value}'),
                  const Divider(height: 28),
                  Text(
                    'Next action',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(lead.nextStep),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final OpsData data;
  final ValueChanged<OpsData> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const SectionHeader(
          title: 'Staff training',
          subtitle: 'Course readiness for each operating team',
        ),
        const SizedBox(height: 12),
        ...data.courses.map(
          (course) => TrainingCard(
            course: course,
            onAdvance: () {
              final updated = data.courses
                  .map(
                    (item) => item.id == course.id
                        ? item.copyWith(
                            progress: (item.progress + 10)
                                .clamp(0, 100)
                                .toInt(),
                          )
                        : item,
                  )
                  .toList();
              onChanged(data.copyWith(courses: updated));
            },
          ),
        ),
      ],
    );
  }
}

class VisitorsScreen extends StatelessWidget {
  const VisitorsScreen({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final OpsData data;
  final ValueChanged<OpsData> onChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-visitor'),
        onPressed: () => _showVisitorDialog(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add visitor'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          const SectionHeader(
            title: 'Visitor desk',
            subtitle: 'Expected arrivals and host status',
          ),
          const SizedBox(height: 12),
          ...data.visitors.map(
            (visitor) => VisitorCard(
              visitor: visitor,
              onToggle: () {
                final updated = data.visitors.map((item) {
                  if (item.id != visitor.id) return item;
                  final next = item.status == 'Checked in'
                      ? 'Scheduled'
                      : 'Checked in';
                  return item.copyWith(status: next);
                }).toList();
                onChanged(data.copyWith(visitors: updated));
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showVisitorDialog(BuildContext context) async {
    final visitor = await showDialog<VisitorRecord>(
      context: context,
      builder: (context) => const VisitorDialog(),
    );

    if (visitor == null) return;
    onChanged(data.copyWith(visitors: [visitor, ...data.visitors]));
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final OpsData data;
  final ValueChanged<OpsData> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const SectionHeader(
          title: 'Settings and privacy',
          subtitle: 'Local workspace preferences',
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: data.localReviewAlerts,
                onChanged: (value) =>
                    onChanged(data.copyWith(localReviewAlerts: value)),
                secondary: const Icon(Icons.notifications_active_outlined),
                title: const Text('Local review alerts'),
                subtitle: const Text(
                  'Show review prompts inside the app workspace.',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Device-only records'),
                subtitle: const Text(
                  'Operations, leads, training, visitors, and preferences stay in local app storage.',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: const Text('Support contact'),
                subtitle: const Text(supportEmail),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workspace summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                SummaryRow(
                  label: 'Resource plans',
                  value: '${data.resources.length}',
                ),
                SummaryRow(
                  label: 'Lead records',
                  value: '${data.leads.length}',
                ),
                SummaryRow(
                  label: 'Training courses',
                  value: '${data.courses.length}',
                ),
                SummaryRow(
                  label: 'Visitor entries',
                  value: '${data.visitors.length}',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ResourcePlanCard extends StatelessWidget {
  const ResourcePlanCard({super.key, required this.plan});

  final ResourcePlan plan;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withAlpha(24),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.area,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text('Owner: ${plan.owner}'),
                    ],
                  ),
                ),
                StatusPill(
                  label: plan.status,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(plan.demand),
            const SizedBox(height: 8),
            Text(
              plan.window,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FocusItem extends StatelessWidget {
  const FocusItem({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.tertiary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(detail),
      ),
    );
  }
}

class LeadCard extends StatelessWidget {
  const LeadCard({super.key, required this.lead, required this.onTap});

  final LeadRecord lead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = lead.company.trim().isEmpty
        ? '?'
        : lead.company.trim().substring(0, 1).toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.secondary.withAlpha(28),
          child: Text(initial),
        ),
        title: Text(
          lead.company,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('${lead.owner} - ${lead.nextStep}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              lead.value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(lead.stage),
          ],
        ),
      ),
    );
  }
}

class TrainingCard extends StatelessWidget {
  const TrainingCard({
    super.key,
    required this.course,
    required this.onAdvance,
  });

  final CourseRecord course;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    course.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                StatusPill(
                  label: '${course.progress}%',
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('${course.team} - next session ${course.nextSession}'),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: course.progress / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: course.progress >= 100 ? null : onAdvance,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark progress'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VisitorCard extends StatelessWidget {
  const VisitorCard({super.key, required this.visitor, required this.onToggle});

  final VisitorRecord visitor;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final checkedIn = visitor.status == 'Checked in';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: checkedIn
              ? const Color(0xFF4F6F52).withAlpha(34)
              : Theme.of(context).colorScheme.primary.withAlpha(24),
          child: Icon(
            checkedIn ? Icons.verified_outlined : Icons.schedule,
            color: checkedIn
                ? const Color(0xFF4F6F52)
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          visitor.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('${visitor.host} - ${visitor.window}'),
        trailing: TextButton(onPressed: onToggle, child: Text(visitor.status)),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class ResourceDialog extends StatefulWidget {
  const ResourceDialog({super.key});

  @override
  State<ResourceDialog> createState() => _ResourceDialogState();
}

class _ResourceDialogState extends State<ResourceDialog> {
  final area = TextEditingController();
  final owner = TextEditingController();
  final demand = TextEditingController();
  final window = TextEditingController(text: 'Today 14:00');

  @override
  void dispose() {
    area.dispose();
    owner.dispose();
    demand.dispose();
    window.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RecordDialogFrame(
      title: 'New allocation',
      fields: [
        AppTextField(
          key: const Key('resource-area'),
          controller: area,
          label: 'Area',
        ),
        AppTextField(controller: owner, label: 'Owner'),
        AppTextField(controller: demand, label: 'Resource need'),
        AppTextField(controller: window, label: 'Time window'),
      ],
      onSave: () {
        if (area.text.trim().isEmpty || owner.text.trim().isEmpty) return;
        Navigator.of(context).pop(
          ResourcePlan(
            id: newId(),
            area: area.text.trim(),
            owner: owner.text.trim(),
            demand: demand.text.trim().isEmpty
                ? 'Coverage review'
                : demand.text.trim(),
            status: 'Pending',
            window: window.text.trim().isEmpty ? 'Today' : window.text.trim(),
          ),
        );
      },
    );
  }
}

class LeadDialog extends StatefulWidget {
  const LeadDialog({super.key});

  @override
  State<LeadDialog> createState() => _LeadDialogState();
}

class _LeadDialogState extends State<LeadDialog> {
  final company = TextEditingController();
  final owner = TextEditingController();
  final value = TextEditingController(text: 'EUR 8k');
  final nextStep = TextEditingController(text: 'Schedule review call');

  @override
  void dispose() {
    company.dispose();
    owner.dispose();
    value.dispose();
    nextStep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RecordDialogFrame(
      title: 'Add lead',
      fields: [
        AppTextField(
          key: const Key('lead-company'),
          controller: company,
          label: 'Company',
        ),
        AppTextField(
          key: const Key('lead-owner'),
          controller: owner,
          label: 'Owner',
        ),
        AppTextField(controller: value, label: 'Estimated value'),
        AppTextField(controller: nextStep, label: 'Next action'),
      ],
      onSave: () {
        if (company.text.trim().isEmpty || owner.text.trim().isEmpty) return;
        Navigator.of(context).pop(
          LeadRecord(
            id: newId(),
            company: company.text.trim(),
            owner: owner.text.trim(),
            value: value.text.trim().isEmpty ? 'EUR 5k' : value.text.trim(),
            stage: 'Qualified',
            nextStep: nextStep.text.trim().isEmpty
                ? 'Confirm next action'
                : nextStep.text.trim(),
          ),
        );
      },
    );
  }
}

class VisitorDialog extends StatefulWidget {
  const VisitorDialog({super.key});

  @override
  State<VisitorDialog> createState() => _VisitorDialogState();
}

class _VisitorDialogState extends State<VisitorDialog> {
  final name = TextEditingController();
  final host = TextEditingController();
  final window = TextEditingController(text: 'Today 11:30');

  @override
  void dispose() {
    name.dispose();
    host.dispose();
    window.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RecordDialogFrame(
      title: 'Add visitor',
      fields: [
        AppTextField(
          key: const Key('visitor-name'),
          controller: name,
          label: 'Visitor name',
        ),
        AppTextField(controller: host, label: 'Host'),
        AppTextField(controller: window, label: 'Arrival window'),
      ],
      onSave: () {
        if (name.text.trim().isEmpty || host.text.trim().isEmpty) return;
        Navigator.of(context).pop(
          VisitorRecord(
            id: newId(),
            name: name.text.trim(),
            host: host.text.trim(),
            window: window.text.trim().isEmpty ? 'Today' : window.text.trim(),
            status: 'Scheduled',
          ),
        );
      },
    );
  }
}

class RecordDialogFrame extends StatelessWidget {
  const RecordDialogFrame({
    super.key,
    required this.title,
    required this.fields,
    required this.onSave,
  });

  final String title;
  final List<Widget> fields;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final field in fields) ...[field, const SizedBox(height: 12)],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('save-record'),
          onPressed: onSave,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      textInputAction: TextInputAction.next,
    );
  }
}

class LocalStore {
  LocalStore({required this.screenshotMode});

  static const _storageKey = 'bordeaux_elisabeth_ops_v1';

  final bool screenshotMode;

  Future<OpsData> load() async {
    if (screenshotMode) return OpsData.sample();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return OpsData.sample();

    try {
      return OpsData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return OpsData.sample();
    } on TypeError {
      return OpsData.sample();
    }
  }

  Future<void> save(OpsData data) async {
    if (screenshotMode) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(data.toJson()));
  }
}

class OpsData {
  const OpsData({
    required this.resources,
    required this.leads,
    required this.courses,
    required this.visitors,
    required this.localReviewAlerts,
  });

  final List<ResourcePlan> resources;
  final List<LeadRecord> leads;
  final List<CourseRecord> courses;
  final List<VisitorRecord> visitors;
  final bool localReviewAlerts;

  OpsData copyWith({
    List<ResourcePlan>? resources,
    List<LeadRecord>? leads,
    List<CourseRecord>? courses,
    List<VisitorRecord>? visitors,
    bool? localReviewAlerts,
  }) {
    return OpsData(
      resources: resources ?? this.resources,
      leads: leads ?? this.leads,
      courses: courses ?? this.courses,
      visitors: visitors ?? this.visitors,
      localReviewAlerts: localReviewAlerts ?? this.localReviewAlerts,
    );
  }

  Map<String, dynamic> toJson() => {
    'resources': resources.map((item) => item.toJson()).toList(),
    'leads': leads.map((item) => item.toJson()).toList(),
    'courses': courses.map((item) => item.toJson()).toList(),
    'visitors': visitors.map((item) => item.toJson()).toList(),
    'localReviewAlerts': localReviewAlerts,
  };

  factory OpsData.fromJson(Map<String, dynamic> json) {
    return OpsData(
      resources: readList(json['resources'], ResourcePlan.fromJson),
      leads: readList(json['leads'], LeadRecord.fromJson),
      courses: readList(json['courses'], CourseRecord.fromJson),
      visitors: readList(json['visitors'], VisitorRecord.fromJson),
      localReviewAlerts: json['localReviewAlerts'] as bool? ?? true,
    );
  }

  factory OpsData.sample() {
    return OpsData(
      resources: const [
        ResourcePlan(
          id: 'r1',
          area: 'Reception coverage',
          owner: 'Elise Martin',
          demand: 'Two trained staff from 09:00 to 13:00 for visitor intake.',
          status: 'Confirmed',
          window: 'Today 09:00-13:00',
        ),
        ResourcePlan(
          id: 'r2',
          area: 'Sales support desk',
          owner: 'Marc Delmas',
          demand:
              'One coordinator to prepare proposal files and meeting rooms.',
          status: 'Pending',
          window: 'Today 14:00-18:00',
        ),
      ],
      leads: const [
        LeadRecord(
          id: 'l1',
          company: 'Garonne Services',
          owner: 'Noa Bertrand',
          value: 'EUR 18k',
          stage: 'Proposal',
          nextStep: 'Send resource plan by 16:00.',
        ),
        LeadRecord(
          id: 'l2',
          company: 'Quai Invest',
          owner: 'Lea Fournier',
          value: 'EUR 11k',
          stage: 'Qualified',
          nextStep: 'Book site walkthrough.',
        ),
        LeadRecord(
          id: 'l3',
          company: 'Cite Atlantique',
          owner: 'Romain Vidal',
          value: 'EUR 7k',
          stage: 'Won',
          nextStep: 'Prepare onboarding tasks.',
        ),
      ],
      courses: const [
        CourseRecord(
          id: 'c1',
          title: 'Visitor reception standards',
          team: 'Front desk',
          progress: 82,
          nextSession: 'Wed 10:00',
        ),
        CourseRecord(
          id: 'c2',
          title: 'Lead qualification workflow',
          team: 'Commercial',
          progress: 68,
          nextSession: 'Thu 15:00',
        ),
        CourseRecord(
          id: 'c3',
          title: 'Resource allocation review',
          team: 'Operations',
          progress: 75,
          nextSession: 'Fri 09:30',
        ),
      ],
      visitors: const [
        VisitorRecord(
          id: 'v1',
          name: 'Helene Roux',
          host: 'Hosted by Elise Martin',
          window: '10:15',
          status: 'Checked in',
        ),
        VisitorRecord(
          id: 'v2',
          name: 'Mathis Caron',
          host: 'Hosted by Marc Delmas',
          window: '14:40',
          status: 'Scheduled',
        ),
        VisitorRecord(
          id: 'v3',
          name: 'Sarah Petit',
          host: 'Hosted by Noa Bertrand',
          window: '16:00',
          status: 'Scheduled',
        ),
      ],
      localReviewAlerts: true,
    );
  }
}

class ResourcePlan {
  const ResourcePlan({
    required this.id,
    required this.area,
    required this.owner,
    required this.demand,
    required this.status,
    required this.window,
  });

  final String id;
  final String area;
  final String owner;
  final String demand;
  final String status;
  final String window;

  Map<String, dynamic> toJson() => {
    'id': id,
    'area': area,
    'owner': owner,
    'demand': demand,
    'status': status,
    'window': window,
  };

  factory ResourcePlan.fromJson(Map<String, dynamic> json) {
    return ResourcePlan(
      id: json['id'] as String? ?? newId(),
      area: json['area'] as String? ?? '',
      owner: json['owner'] as String? ?? '',
      demand: json['demand'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      window: json['window'] as String? ?? 'Today',
    );
  }
}

class LeadRecord {
  const LeadRecord({
    required this.id,
    required this.company,
    required this.owner,
    required this.value,
    required this.stage,
    required this.nextStep,
  });

  final String id;
  final String company;
  final String owner;
  final String value;
  final String stage;
  final String nextStep;

  Map<String, dynamic> toJson() => {
    'id': id,
    'company': company,
    'owner': owner,
    'value': value,
    'stage': stage,
    'nextStep': nextStep,
  };

  factory LeadRecord.fromJson(Map<String, dynamic> json) {
    return LeadRecord(
      id: json['id'] as String? ?? newId(),
      company: json['company'] as String? ?? '',
      owner: json['owner'] as String? ?? '',
      value: json['value'] as String? ?? 'EUR 0',
      stage: json['stage'] as String? ?? 'Qualified',
      nextStep: json['nextStep'] as String? ?? 'Review next action',
    );
  }
}

class CourseRecord {
  const CourseRecord({
    required this.id,
    required this.title,
    required this.team,
    required this.progress,
    required this.nextSession,
  });

  final String id;
  final String title;
  final String team;
  final int progress;
  final String nextSession;

  CourseRecord copyWith({int? progress}) {
    return CourseRecord(
      id: id,
      title: title,
      team: team,
      progress: progress ?? this.progress,
      nextSession: nextSession,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'team': team,
    'progress': progress,
    'nextSession': nextSession,
  };

  factory CourseRecord.fromJson(Map<String, dynamic> json) {
    return CourseRecord(
      id: json['id'] as String? ?? newId(),
      title: json['title'] as String? ?? '',
      team: json['team'] as String? ?? '',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      nextSession: json['nextSession'] as String? ?? 'TBD',
    );
  }
}

class VisitorRecord {
  const VisitorRecord({
    required this.id,
    required this.name,
    required this.host,
    required this.window,
    required this.status,
  });

  final String id;
  final String name;
  final String host;
  final String window;
  final String status;

  VisitorRecord copyWith({String? status}) {
    return VisitorRecord(
      id: id,
      name: name,
      host: host,
      window: window,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'host': host,
    'window': window,
    'status': status,
  };

  factory VisitorRecord.fromJson(Map<String, dynamic> json) {
    return VisitorRecord(
      id: json['id'] as String? ?? newId(),
      name: json['name'] as String? ?? '',
      host: json['host'] as String? ?? '',
      window: json['window'] as String? ?? 'Today',
      status: json['status'] as String? ?? 'Scheduled',
    );
  }
}

List<T> readList<T>(
  Object? raw,
  T Function(Map<String, dynamic> json) convert,
) {
  if (raw is! List) return <T>[];

  return raw
      .whereType<Map>()
      .map((item) => convert(Map<String, dynamic>.from(item)))
      .toList();
}

String newId() => DateTime.now().microsecondsSinceEpoch.toString();
