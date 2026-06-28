import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import { en } from "@/locales/en";
import { fr } from "@/locales/fr";

// FR + EN from V1. Browser language decides; falls back to EN.
const browser = navigator.language.startsWith("fr") ? "fr" : "en";

void i18n.use(initReactI18next).init({
  resources: { en, fr },
  lng: browser,
  fallbackLng: "en",
  interpolation: { escapeValue: false },
});

export default i18n;
