module.exports = {
  darkMode: 'media',
  content: [
    "./js/**/*.js",
    "../lib/**/*.ex",
    "../lib/**/*.heex",
  ],
  plugins: [
    require("@tailwindcss/typography"),
  ]
};
