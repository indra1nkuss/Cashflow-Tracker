import { PrismaClient, TransactionType } from '@prisma/client';

const prisma = new PrismaClient();

const defaultCategories = [
  // Expense categories
  { name: 'Makanan & Minuman', type: TransactionType.EXPENSE, icon: 'restaurant', color: '#EF4444' },
  { name: 'Transportasi', type: TransactionType.EXPENSE, icon: 'directions_car', color: '#F59E0B' },
  { name: 'Belanja', type: TransactionType.EXPENSE, icon: 'shopping_bag', color: '#EC4899' },
  { name: 'Tagihan & Utilitas', type: TransactionType.EXPENSE, icon: 'receipt', color: '#6366F1' },
  { name: 'Hiburan', type: TransactionType.EXPENSE, icon: 'movie', color: '#8B5CF6' },
  { name: 'Kesehatan', type: TransactionType.EXPENSE, icon: 'medical_services', color: '#10B981' },
  { name: 'Pendidikan', type: TransactionType.EXPENSE, icon: 'school', color: '#3B82F6' },
  { name: 'Pengeluaran Lainnya', type: TransactionType.EXPENSE, icon: 'more_horiz', color: '#6B7280' },

  // Income categories
  { name: 'Gaji', type: TransactionType.INCOME, icon: 'payments', color: '#10B981' },
  { name: 'Freelance & Usaha', type: TransactionType.INCOME, icon: 'work', color: '#06B6D4' },
  { name: 'Investasi', type: TransactionType.INCOME, icon: 'trending_up', color: '#3B82F6' },
  { name: 'Hadiah & Bonus', type: TransactionType.INCOME, icon: 'card_giftcard', color: '#EC4899' },
  { name: 'Pemasukan Lainnya', type: TransactionType.INCOME, icon: 'add_circle', color: '#6B7280' },
];

async function main() {
  console.log('🌱 Seeding database default categories...');

  for (const cat of defaultCategories) {
    const existing = await prisma.category.findFirst({
      where: {
        name: cat.name,
        userId: null,
        isDefault: true,
      },
    });

    if (!existing) {
      await prisma.category.create({
        data: {
          name: cat.name,
          type: cat.type,
          icon: cat.icon,
          color: cat.color,
          isDefault: true,
          userId: null,
        },
      });
      console.log(`  ✓ Created default category: ${cat.name} (${cat.type})`);
    } else {
      console.log(`  - Category already exists: ${cat.name}`);
    }
  }

  console.log('✅ Seeding completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

