import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { VitePWA } from "vite-plugin-pwa";

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: "prompt",
      includeAssets: [
        "icon.svg",
        "icon-192.png",
        "icon-512.png",
        "manrope.ttf",
      ],
      manifest: {
        name: "AlDía — Control de recibos del hogar",
        short_name: "AlDía",
        description:
          "Organiza vencimientos, registra pagos y detecta aumentos.",
        lang: "es-PE",
        theme_color: "#087f6f",
        background_color: "#f3f7f5",
        display: "standalone",
        start_url: "/",
        icons: [
          { src: "/icon-192.png", sizes: "192x192", type: "image/png" },
          {
            src: "/icon-512.png",
            sizes: "512x512",
            type: "image/png",
            purpose: "any maskable",
          },
        ],
      },
      workbox: { globPatterns: ["**/*.{js,css,html,png,svg}"] },
    }),
  ],
});
