# Expense Tracker

A modern, offline-first expense tracking app built with Flutter. Track your income and expenses with ease, visualize your spending patterns, and export your data anytime.

## Features

- **Dashboard** - View your current balance, total income, and expenses at a glance
- **Transactions** - Add, edit, and manage all your income and expense transactions
- **Reports** - Visualize your spending with interactive charts (pie charts and bar graphs)
- **Multi-Currency Support** - Choose your country and track expenses in your local currency
- **Theme Settings** - Light, Dark, or follow system theme with pure black dark mode
- **Accent Color** - Customize the app's accent color
- **Budget System** - Set monthly budgets with spending alerts (50%, 90%, exceeded)
- **Month Navigation** - View transactions and reports for any month
- **Data Export** - Export your transactions as CSV to your device
- **Bug Reporting** - Report issues directly to the developer
- **Offline First** - All data is stored locally on your device

## Getting Started

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd expense_tracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## User Guide

### Account Setup

1. **Sign Up** - When you first open the app:
   - Enter your **Full Name**
   - Enter your **Email**
   - Select your **Country** (this sets your currency symbol)
   - Enter a **Password**
   - Tap **Create Account**

2. **Supported Countries & Currencies**

   | Country | Currency |
   |---------|----------|
   | India | ₹ (INR) |
   | United States | $ (USD) |
   | United Kingdom | £ (GBP) |
   | European Union | € (EUR) |
   | Japan | ¥ (JPY) |
   | Canada | C$ (CAD) |
   | Australia | A$ (AUD) |
   | Singapore | S$ (SGD) |

3. **Sign In** - Use your registered email and password to access your account.
4. **Logout** - Go to Settings > Account > Logout to sign out.

### Managing Transactions

#### Adding a Transaction

1. Navigate to the **Home** tab
2. Tap the **Add** button (floating action button)
3. Fill in the transaction details:
   - **Title** - Give your transaction a name (e.g., "Grocery Shopping")
   - **Amount** - Enter the amount in your selected currency
   - **Type** - Select **Income** (money in) or **Expense** (money out)
   - **Category** - Choose a category (Food, Transport, Shopping, Bills, Entertainment, Health, Other)
   - **Date** - Select the date of the transaction (defaults to today)
   - **Note** - Add an optional note or description
4. Tap **Save** to add the transaction

#### Viewing & Editing Transactions

1. Go to the **Transactions** tab
2. Browse all your transactions sorted by date (newest first)
3. **Edit** a transaction by swiping right
4. **Delete** a transaction by swiping left
5. **Filter** transactions using the filter button:
   - Filter by category
   - Filter by type (income/expense)
   - Filter by date range
   - Search by title or note

### Dashboard

The Home tab shows:
- **Current Balance** - Your total balance (income minus expenses)
- **Income Card** - Total money received
- **Expense Card** - Total money spent
- **Recent Transactions** - Your last 5 transactions

### Reports & Analytics

1. Go to the **Reports** tab
2. View your **Spending by Category** pie chart
3. View **Monthly Overview** bar graph
4. See **Total Income** and **Total Expenses** summary cards

### Settings

#### Theme Settings
- **Theme** - Toggle between Light, Dark, or System theme
- Light mode uses clean white backgrounds
- Dark mode uses pure black for OLED screens
- Theme follows your device's system setting by default

#### Accent Color
1. Go to **Settings** > **Appearance**
2. Tap **Accent Color**
3. Choose from 8 preset colors
4. The selected color applies throughout the app

#### Budget System
1. Go to **Settings** > **Budget**
2. Tap **No Budget Set** (or existing budget)
3. Enter your monthly budget amount
4. The app tracks your spending and shows alerts when you reach:
   - **50%** of budget - Warning banner
   - **90%** - Alert banner
   - **100%+** - Exceeded banner
5. Swipe up on banners to dismiss them

#### Data Export
1. Go to **Settings** > **Data**
2. Tap **Export Transactions**
3. Choose where you want to save the CSV file
4. The file contains: ID, Title, Amount, Type, Category, Date, and Note

#### Help & Support
- **Report a Bug** - Tap to open your email app with a bug report template
- Send feedback to: deepmujpara@gmail.com

#### Account
- **Logout** - Sign out of your account

## Categories

The app includes these predefined categories:

| Category | Icon |
|----------|------|
| Food | 🍔 |
| Transport | 🚗 |
| Shopping | 🛒 |
| Bills | 📄 |
| Entertainment | 🎬 |
| Health | 💊 |
| Other | 📦 |

## Data Storage

- All your data is stored locally using **Hive** database
- Data persists even when you close the app
- User preferences (country, currency) are stored securely
- Export your data regularly to keep a backup

## Troubleshooting

**App crashes on startup?**
- Clear app cache and restart
- Ensure you have the latest version of Flutter

**Data not saving?**
- Check if you have sufficient storage space
- Try logging out and logging back in

**Export not working?**
- Ensure you have granted necessary file permissions
- Check if you have enough storage space

**Currency not showing correctly?**
- The currency is set based on your selected country during signup
- It cannot be changed after signup (create a new account to change)

## Support

For issues or feature requests:
- **Bug Reports** - Use the in-app "Report a Bug" feature in Settings
- **Email** - Contact: deepmujpara@gmail.com
