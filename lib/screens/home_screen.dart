import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/folder_provider.dart';
import '../services/storage_service.dart';
import '../services/web_file_helper.dart';
import '../widgets/folder_card.dart';
import '../widgets/create_folder_dialog.dart';
import 'folder_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _storageInfo = '계산 중...';

  @override
  void initState() {
    super.initState();
    _updateStorageInfo();
  }

  Future<void> _updateStorageInfo() async {
    final storage = StorageService();
    final totalSize = await storage.getTotalStorageSize();
    final totalMedia = (await storage.getAllMedia()).length;
    
    if (mounted) {
      setState(() {
        _storageInfo = '${WebFileHelper.formatBytes(totalSize)} (${totalMedia}개 미디어)';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Media Studio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: _buildBody(),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateFolderDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('새 폴더'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: '폴더',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_outlined),
            selectedIcon: Icon(Icons.collections),
            label: '갤러리',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildFoldersView();
      case 1:
        return _buildGalleryView();
      case 2:
        return _buildSettingsView();
      default:
        return _buildFoldersView();
    }
  }

  Widget _buildFoldersView() {
    return Consumer<FolderProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.folders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_off_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  '폴더가 없습니다',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '새 폴더 버튼을 눌러 폴더를 만들어보세요',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: provider.folders.length,
          itemBuilder: (context, index) {
            final folder = provider.folders[index];
            return FolderCard(
              folder: folder,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FolderDetailScreen(folder: folder),
                  ),
                );
              },
              onDelete: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('폴더 삭제'),
                    content: const Text('이 폴더와 모든 미디어를 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await provider.deleteFolder(folder.id);
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGalleryView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.collections_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '전체 갤러리',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '곧 추가될 예정입니다',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('앱 정보'),
          subtitle: const Text('Media Studio v1.0.0'),
        ),
        ListTile(
          leading: const Icon(Icons.storage_outlined),
          title: const Text('저장소 사용량'),
          subtitle: Text(_storageInfo),
          trailing: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateStorageInfo,
            tooltip: '새로고침',
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.phone_android),
          title: const Text('플랫폼'),
          subtitle: const Text('웹 브라우저'),
        ),
        ListTile(
          leading: const Icon(Icons.cloud_off),
          title: const Text('저장 방식'),
          subtitle: const Text('로컬 브라우저 저장소 (IndexedDB)'),
        ),
      ],
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateFolderDialog(),
    );
  }
}
