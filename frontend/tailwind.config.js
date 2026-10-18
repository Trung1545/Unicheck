/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Stitch "Academic Precision" Brand Palette
        primary: {
          50: '#EFF6FF',
          100: '#DBEAFE',
          200: '#BFDBFE',
          300: '#93C5FD',
          400: '#60A5FA',
          500: '#3B82F6',
          600: '#2563EB',
          700: '#1D4ED8', // Primary brand color
          800: '#1E40AF', // Primary dark hover
          900: '#1E3A8A',
          950: '#172554',
          DEFAULT: '#1D4ED8',
        },
        // Stitch Teal Accent Palette (Biometric & Dynamic Validation)
        accent: {
          50: '#F0FDFA',
          100: '#CCFBF1',
          200: '#99F6E4',
          300: '#5EEAD4',
          400: '#2DD4BF',
          500: '#14B8A6', // Primary accent
          600: '#0D9488',
          700: '#0F766E',
          800: '#115E59',
          900: '#134E4A',
          DEFAULT: '#14B8A6',
        },
        // Semantic Attendance Status Badges
        attendance: {
          present: {
            DEFAULT: '#10B981',
            bg: '#ECFDF5',
            border: '#A7F3D0',
            text: '#065F46',
          },
          late: {
            DEFAULT: '#F59E0B',
            bg: '#FFFBEB',
            border: '#FDE68A',
            text: '#92400E',
          },
          absent: {
            DEFAULT: '#EF4444',
            bg: '#FEF2F2',
            border: '#FECACA',
            text: '#991B1B',
          },
          excused: {
            DEFAULT: '#3B82F6',
            bg: '#EFF6FF',
            border: '#BFDBFE',
            text: '#1E40AF',
          },
        },
        // Structural Surface & Outline
        surface: {
          canvas: '#F8FAFC',
          card: '#FFFFFF',
          muted: '#F1F5F9',
          border: '#E2E8F0',
          'border-active': '#93C5FD',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
      },
      borderRadius: {
        sm: '0.25rem', // 4px
        DEFAULT: '0.5rem', // 8px
        md: '0.75rem', // 12px
        lg: '1rem', // 16px
        xl: '1.5rem', // 24px
      },
      boxShadow: {
        'card': '0 1px 3px 0 rgba(15, 23, 42, 0.05), 0 1px 2px -1px rgba(15, 23, 42, 0.05)',
        'card-hover': '0 4px 6px -1px rgba(15, 23, 42, 0.07), 0 2px 4px -2px rgba(15, 23, 42, 0.05)',
        'dropdown': '0 10px 15px -3px rgba(15, 23, 42, 0.08), 0 4px 6px -4px rgba(15, 23, 42, 0.04)',
        'modal': '0 20px 25px -5px rgba(15, 23, 42, 0.1), 0 8px 10px -6px rgba(15, 23, 42, 0.06)',
      },
      spacing: {
        'gutter': '1.5rem',
        'gutter-sm': '1rem',
        'margin-app': '2rem',
        'margin-mobile': '1rem',
        'space-xs': '0.25rem',
        'space-sm': '0.5rem',
        'space-md': '0.75rem',
        'space-lg': '1rem',
        'space-xl': '1.5rem',
        'space-2xl': '2rem',
      },
    },
  },
  plugins: [],
}
