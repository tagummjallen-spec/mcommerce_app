import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../widgets/product_card.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Sync the local search box with any discipline tap from Home.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filter = ref.read(shopFilterProvider);
      if (_searchController.text != filter.searchQuery) {
        _searchController.text = filter.searchQuery;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _sortLabel(String sort) {
    switch (sort) {
      case 'price_asc':
        return 'Price: Low to High';
      case 'price_desc':
        return 'Price: High to Low';
      case 'name':
        return 'Name: A - Z';
      default:
        return 'Newest';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(shopFilterProvider);
    final filtered = ref.watch(filteredProductsProvider);
    final cartCount = ref.watch(cartItemCountProvider);

    final activeFilterCount =
        (filter.discipline != 'All' ? 1 : 0) +
        (filter.productType != 'All' ? 1 : 0);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('SHOP'),
        actions: [
          IconButton(
            tooltip: 'Cart',
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              backgroundColor: AppColors.primaryAccent,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            onPressed: () => context.go('/cart'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // ===== Search bar =====
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  ref.read(shopFilterProvider.notifier).setSearch(value),
              style: const TextStyle(color: AppColors.primaryText),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.secondaryText,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.secondaryText,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(shopFilterProvider.notifier).setSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // ===== Filter + sort row =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Filters button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openFilterSheet,
                    icon: Badge(
                      isLabelVisible: activeFilterCount > 0,
                      label: Text('$activeFilterCount'),
                      backgroundColor: AppColors.primaryAccent,
                      child: const Icon(Icons.tune, size: 18),
                    ),
                    label: const Text('Filters'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Sort dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: filter.sortBy,
                    key: ValueKey<String>(filter.sortBy),
                    dropdownColor: AppColors.secondarySurface,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 13,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.secondaryText,
                      size: 20,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.sort,
                        color: AppColors.secondaryText,
                        size: 18,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'newest',
                        child: Text(
                          'Newest',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'price_asc',
                        child: Text(
                          'Price: Low-High',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'price_desc',
                        child: Text(
                          'Price: High-Low',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'name',
                        child: Text(
                          'Name: A-Z',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(shopFilterProvider.notifier).setSort(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // ===== Active filter chips =====
          if (filter.discipline != 'All' || filter.productType != 'All')
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (filter.discipline != 'All')
                      _ActiveFilterChip(
                        label: filter.discipline,
                        onRemove: () => ref
                            .read(shopFilterProvider.notifier)
                            .setDiscipline('All'),
                      ),
                    if (filter.productType != 'All')
                      _ActiveFilterChip(
                        label: filter.productType,
                        onRemove: () => ref
                            .read(shopFilterProvider.notifier)
                            .setProductType('All'),
                      ),
                    _ActiveFilterChip(
                      label: 'Clear all',
                      onRemove: () =>
                          ref.read(shopFilterProvider.notifier).reset(),
                      isClearAll: true,
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

          // ===== Result count =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    filtered.maybeWhen(
                      data: (items) =>
                          '${items.length} product${items.length == 1 ? '' : 's'}',
                      orElse: () => '',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sorted by: ${_sortLabel(filter.sortBy)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ===== Product grid =====
          Expanded(
            child: filtered.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryAccent,
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Failed to load products.',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.invalidate(productsProvider),
                      child: const Text(
                        'Retry',
                        style: TextStyle(color: AppColors.primaryAccent),
                      ),
                    ),
                  ],
                ),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            color: AppColors.tertiaryText,
                            size: 52,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No products found',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try adjusting your search or filters.',
                            style: TextStyle(color: AppColors.secondaryText),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          OutlinedButton(
                            onPressed: () {
                              _searchController.clear();
                              ref.read(shopFilterProvider.notifier).reset();
                            },
                            child: const Text('Clear Filters'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primaryAccent,
                  backgroundColor: AppColors.secondarySurface,
                  onRefresh: () async => ref.invalidate(productsProvider),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: products.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.62,
                        ),
                    itemBuilder: (context, index) => ProductCard(
                      product: products[index],
                      width: double.infinity,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openFilterSheet() {
    final filter = ref.read(shopFilterProvider);
    String discipline = filter.discipline;
    String productType = filter.productType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secondarySurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.borderLight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filters',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                discipline = 'All';
                                productType = 'All';
                              });
                            },
                            child: const Text(
                              'Reset',
                              style: TextStyle(color: AppColors.secondaryText),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Discipline',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppConstants.disciplines.map((d) {
                          final selected = discipline == d;
                          return ChoiceChip(
                            label: Text(d),
                            selected: selected,
                            selectedColor: AppColors.primaryAccent,
                            backgroundColor: AppColors.cardSurface,
                            labelStyle: TextStyle(
                              color: selected
                                  ? AppColors.primaryText
                                  : AppColors.secondaryText,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? AppColors.primaryAccent
                                  : AppColors.border,
                            ),
                            onSelected: (_) =>
                                setSheetState(() => discipline = d),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Product Type',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppConstants.productTypes.map((t) {
                          final selected = productType == t;
                          return ChoiceChip(
                            label: Text(t),
                            selected: selected,
                            selectedColor: AppColors.primaryAccent,
                            backgroundColor: AppColors.cardSurface,
                            labelStyle: TextStyle(
                              color: selected
                                  ? AppColors.primaryText
                                  : AppColors.secondaryText,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? AppColors.primaryAccent
                                  : AppColors.border,
                            ),
                            onSelected: (_) =>
                                setSheetState(() => productType = t),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final notifier = ref.read(
                              shopFilterProvider.notifier,
                            );
                            notifier.setDiscipline(discipline);
                            notifier.setProductType(productType);
                            Navigator.pop(sheetCtx);
                          },
                          child: const Text('APPLY FILTERS'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final bool isClearAll;

  const _ActiveFilterChip({
    required this.label,
    required this.onRemove,
    this.isClearAll = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        labelStyle: TextStyle(
          color: isClearAll ? AppColors.error : AppColors.primaryText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: isClearAll
            ? AppColors.error.withValues(alpha: 0.12)
            : AppColors.primaryAccent.withValues(alpha: 0.16),
        side: BorderSide(
          color: isClearAll
              ? AppColors.error.withValues(alpha: 0.5)
              : AppColors.primaryAccent.withValues(alpha: 0.5),
        ),
        deleteIcon: Icon(
          isClearAll ? Icons.block : Icons.close,
          size: 15,
          color: isClearAll ? AppColors.error : AppColors.secondaryText,
        ),
        onDeleted: onRemove,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
