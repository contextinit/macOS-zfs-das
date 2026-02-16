# macOS ZFS DAS - Public Documentation Website

Professional React-based documentation and marketing website for the macOS ZFS DAS project.

## 🚀 Quick Start

### Prerequisites

1. **Install Node.js** (if not already installed):
```bash
brew install node
```

2. **Verify installation**:
```bash
node --version  # Should show v18+
npm --version   # Should show v9+
```

### Installation

```bash
cd website
npm install
```

### Development

```bash
npm run dev
```

Visit `http://localhost:3000` to see the site.

### Build for Production

```bash
npm run build
```

The `dist/` folder contains static files ready for deployment.

## 📁 Project Structure

```
website/
├── public/
│   ├── favicon.svg
│   └── images/
│       ├── hero-illustration.png (AI-generated)
│       └── pool-diagram.svg
├── src/
│   ├── components/
│   │   ├── layout/
│   │   │   ├── Navbar.jsx           # Responsive navigation
│   │   │   └── Footer.jsx           # Footer with links
│   │   ├── home/
│   │   │   ├── Hero.jsx             # Hero section
│   │   │   ├── Features.jsx         # Feature cards
│   │   │   ├── Benefits.jsx         # User benefits
│   │   │   ├── UseCases.jsx         # Real-world examples
│   │   │   └── ContactForm.jsx      # Contact/consultation form
│   │   ├── wizards/
│   │   │   ├── PoolCreationWizard.jsx
│   │   │   ├── SwiftBarWizard.jsx
│   │   │   ├── TimeMachineWizard.jsx
│   │   │   └── shared/
│   │   │       ├── StepIndicator.jsx
│   │   │       ├── CommandBlock.jsx
│   │   │       └── WizardContainer.jsx
│   │   └── common/
│   │       ├── Button.jsx
│   │       ├── Card.jsx
│   │       └── Badge.jsx
│   ├── pages/
│   │   ├── Home.jsx
│   │   ├── GettingStarted.jsx
│   │   ├── Wizards.jsx
│   │   ├── Documentation.jsx
│   │   └── Download.jsx
│   ├── styles/
│   │   └── index.css               # Tailwind + custom styles
│   ├── App.jsx                     # Main app with routing
│   └── main.jsx                    # Entry point
├── index.html                       # HTML template
├── package.json                     # Dependencies
├── vite.config.js                  # Vite configuration
├── tailwind.config.js              # Tailwind configuration
└── postcss.config.js               # PostCSS configuration
```

## 🎨 Features

### ✅ Completed
- **Responsive Design**: Mobile-first, works on all devices
- **Modern UI**: Tailwind CSS with custom color scheme
- **Interactive Wizards**: 3 step-by-step wizards
  - Pool Creation Wizard (5 steps)
  - SwiftBar Setup Wizard (5 steps)
  - Time Machine Wizard (5 steps)
- **Contact Form**: With consultation request option
- **Newsletter Signup**: Integrated into contact form
- **Progress Indicators**: Visual wizard progress tracking
- **Command Blocks**: Copy-to-clipboard functionality
- **Google Analytics**: Ready for GA tracking code
- **SEO Optimized**: Meta tags, semantic HTML

### 🎯 Wizards

#### 1. Pool Creation Wizard
- Select RAID type (mirror, RAID-Z, RAID-Z2, RAID-Z3)
- Choose drives
- Configure compression (LZ4, gzip, zstd)
- Enable AES-256-GCM encryption
- Generates custom commands

#### 2. SwiftBar Setup Wizard
- Check Homebrew installation
- Install SwiftBar
- Choose monitoring level (basic/advanced)
- Copy plugin to SwiftBar directory

#### 3. Time Machine Wizard
- Create ZFS dataset
- Set quota and permissions
- Configure SMB sharing
- Connect Mac clients

## 🎨 Design System

### Colors
- **Primary**: `#1E40AF` (Deep Blue)
- **Accent**: `#14B8A6` (Teal)
- **Success**: `#10B981` (Green)
- **Warning**: `#F59E0B` (Amber)
- **Error**: `#EF4444` (Red)

### Typography
- **Sans**: Inter
- **Mono**: JetBrains Mono

### Components
All components support hover effects and are fully accessible.

## 🚀 Deployment to Hostinger

### Method 1: FTP/SFTP Upload

1. Build the site:
```bash
npm run build
```

2. Upload contents of `dist/` folder to your Hostinger public_html directory

3. Update domain DNS to point to: `MacOSZFS.Contextinit.com`

### Method 2: GitHub Actions (Recommended)

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Hostinger

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install and Build
        run: |
          cd website
          npm install
          npm run build
      
      - name: Deploy to Hostinger
        uses: SamKirkland/FTP-Deploy-Action@4.3.3
        with:
          server: ftp.yourhostinger.com
          username: ${{ secrets.FTP_USERNAME }}
          password: ${{ secrets.FTP_PASSWORD }}
          local-dir: ./website/dist/
          server-dir: /public_html/
```

## 📧 Configuration

### Google Analytics
Update `index.html` line 13 with your GA tracking ID:
```html
gtag('config', 'YOUR-GA-ID-HERE');
```

### Email Integration
The contact form currently logs to console. To enable:

1. Set up backend API endpoint
2. Update `ContactForm.jsx` line 20:
```javascript
const response = await fetch('YOUR_API_ENDPOINT', {
  method: 'POST',
  body: JSON.stringify(formData),
});
```

### Newsletter
Integrate with your email service (Mailchimp, SendGrid, etc.)

## 🔧 Customization

### Update Brand Colors
Edit `tailwind.config.js`:
```javascript
colors: {
  primary: {
    600: '#YOUR-COLOR',  // Main primary color
  },
  accent: {
    500: '#YOUR-COLOR',  // Main accent color
  },
}
```

### Add New Wizard
1. Create `src/components/wizards/YourWizard.jsx`
2. Follow existing wizard pattern
3. Add route in `src/pages/Wizards.jsx`

## 📝 Todo

- [ ] Replace AI-generated images with final versions
- [ ] Add actual GitHub repository link
- [ ] Configure email backend for contact form
- [ ] Add newsletter service integration
- [ ] Set up Google Analytics with real tracking ID
- [ ] Create additional documentation pages
- [ ] Add search functionality to docs

## 🌐 Live Site

- **URL**: https://MacOSZFS.Contextinit.com
- **Contact**: info@contextinit.com

## 📄 License

MIT License - Context Init LLC © 2024
