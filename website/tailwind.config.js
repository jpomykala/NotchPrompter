/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./privacy-policy.html",
    "./*/index.html",
    "./404.html",
    "./partials/*.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
