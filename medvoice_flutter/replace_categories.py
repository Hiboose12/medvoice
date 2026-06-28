import re

file_path = r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medvoice_flutter\lib\features\operations\presentation\screens\operational_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_categories_page = """class _CategoriesPage extends StatefulWidget {
  const _CategoriesPage();

  @override
  State<_CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<_CategoriesPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addCategory() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    if (name.isEmpty) return;

    final success = await context.read<AdminProvider>().addCategory(name, desc);
    if (success && mounted) {
      _nameController.clear();
      _descController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category added successfully')));
      context.read<AdminProvider>().loadCategories(search: _searchQuery);
    }
  }

  void _deleteCategory(int id) async {
    final success = await context.read<AdminProvider>().deleteCategory(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category deleted successfully')));
      context.read<AdminProvider>().loadCategories(search: _searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add New Category Section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category Name', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'e.g. Medical Negligence',
                            hintStyle: const TextStyle(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Description', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Brief description of when to use this category',
                            hintStyle: const TextStyle(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: adminProv.isLoading ? null : _addCategory,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Search Bar
        TextField(
          controller: _searchController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search categories...',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          ),
          onChanged: (val) {
            _searchQuery = val;
            context.read<AdminProvider>().loadCategories(search: val);
          },
        ),
        const SizedBox(height: 24),
        
        // Table Section
        _Section(
          title: 'Categories List',
          child: adminProv.isLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              : adminProv.categories.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No categories found', style: TextStyle(color: AppColors.textSecondary))))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingTextStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12),
                        dataTextStyle: const TextStyle(color: AppColors.textPrimary),
                        columns: const [
                          DataColumn(label: Text('CATEGORY NAME')),
                          DataColumn(label: Text('DESCRIPTION')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: adminProv.categories.map<DataRow>((cat) {
                          final idStr = cat['id']?.toString() ?? '0';
                          final id = int.tryParse(idStr) ?? 0;
                          final name = cat['name']?.toString() ?? 'Unknown';
                          final desc = cat['description']?.toString() ?? '';
                          final isActive = cat['is_active'] == true;

                          return DataRow(
                            cells: [
                              DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(SizedBox(
                                width: 300,
                                child: Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
                              )),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                TextButton(
                                  onPressed: () => _deleteCategory(id),
                                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
        ),
      ],
    );
  }
}"""

pattern = r"class _CategoriesPage extends StatelessWidget \{.*?\n  \}"
content = re.sub(pattern, new_categories_page, content, flags=re.DOTALL)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated _CategoriesPage successfully")
