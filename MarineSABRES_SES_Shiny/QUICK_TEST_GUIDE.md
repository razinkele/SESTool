# Quick Testing Guide - Language Persistence Fix

**App URL:** http://localhost:3838
**Status:** ✅ Running and ready for testing
**Date:** October 28, 2025

---

## 🎯 What to Test

The sidebar menu should now **fully translate** to any selected language and **persist** across browser sessions.

---

## 📋 Test Steps

### ✅ Test 1: Basic Language Change (2 minutes)

1. **Open:** http://localhost:3838 in your browser
2. **Observe:** App loads in English by default
3. **Click:** Settings icon (⚙️) in top-right corner
4. **Select:** Language → "Français"
5. **Click:** "Apply Changes" button
6. **Expected Result:**
   - Page reloads with URL: `http://localhost:3838?language=fr`
   - **Sidebar menu items in French:**
     - ✅ "Commencer" (Getting Started)
     - ✅ "Tableau de bord" (Dashboard)
     - ✅ "Créer le modèle SES" (Create SES Model)
     - ✅ "Entrée de données ISA" (ISA Data Entry)
     - ✅ "Visualisation CLD" (CLD Visualization)
     - ✅ "Constructeur de scénarios" (Scenario Builder)
     - ✅ "Outils d'analyse" (Analysis Tools)
     - ✅ "Gérer les réponses" (Manage Responses)
     - ✅ "Informations sur le projet" (Project Information)
     - ✅ "Gestion des parties prenantes" (Stakeholder Management)
     - ✅ "Paramètres" (Settings)
   - **Tooltips in French** (hover over menu items)
   - **Quick Actions section in French**

**✅ PASS:** Entire sidebar displays in French
**❌ FAIL:** Any sidebar items still show English text

---

### ✅ Test 2: Language Persistence (1 minute)

1. **After Test 1** (app should be in French)
2. **Close:** Browser completely (close all tabs)
3. **Reopen:** Browser
4. **Navigate to:** http://localhost:3838
5. **Expected Result:**
   - Automatically redirects to `http://localhost:3838?language=fr`
   - App loads directly in French (no flash of English)
   - Sidebar menu immediately in French

**✅ PASS:** Language persists across browser sessions
**❌ FAIL:** App reverts to English

---

### ✅ Test 3: Direct URL Access (30 seconds)

1. **Type directly in browser:** `http://localhost:3838?language=es`
2. **Press Enter**
3. **Expected Result:**
   - App loads in Spanish
   - Sidebar menu items in Spanish:
     - "Primeros Pasos" (Getting Started)
     - "Panel de Control" (Dashboard)
     - "Crear Modelo SES" (Create SES Model)
     - etc.

**Try these URLs:**
- `?language=de` → German
- `?language=it` → Italian
- `?language=pt` → Portuguese
- `?language=lt` → Lithuanian

**✅ PASS:** Each URL parameter loads the correct language
**❌ FAIL:** Language doesn't change or shows errors

---

### ✅ Test 4: All Languages (5 minutes)

Test each language through the Settings menu:

| Language | Flag | Sidebar Item Example | Status |
|----------|------|---------------------|--------|
| **English** | 🇬🇧 | Getting Started | ⬜ |
| **Español** | 🇪🇸 | Primeros Pasos | ⬜ |
| **Français** | 🇫🇷 | Commencer | ⬜ |
| **Deutsch** | 🇩🇪 | Erste Schritte | ⬜ |
| **Lietuvių** | 🇱🇹 | Pradedant | ⬜ |
| **Português** | 🇵🇹 | Primeiros Passos | ⬜ |
| **Italiano** | 🇮🇹 | Per Iniziare | ⬜ |

**For each language:**
1. Open Settings → Language
2. Select language
3. Click "Apply Changes"
4. Verify sidebar translates
5. Check URL has `?language=XX`

---

## 🔍 What to Look For

### ✅ Success Indicators

- **URL changes:** Shows `?language=xx` after language selection
- **Sidebar translates:** All 11 menu items in selected language
- **Tooltips translate:** Hover text changes language
- **Persistence works:** Reopening browser maintains language
- **No flashing:** Page loads directly in saved language
- **No errors:** Browser console shows no JavaScript errors

### ❌ Failure Indicators

- Sidebar menu still in English after language change
- URL doesn't show `?language=xx` parameter
- Page flashes English before switching to selected language
- Language resets to English after closing browser
- JavaScript errors in browser console (F12)
- HTML tags displaying (like `<span class="i18n">...`)

---

## 🐛 If Something Goes Wrong

### Sidebar Still in English

**Check 1:** Open browser console (F12) and look for errors

**Check 2:** Verify URL has language parameter
- Expected: `http://localhost:3838?language=fr`
- If missing: JavaScript redirect may not be working

**Check 3:** Check localStorage in browser console:
```javascript
localStorage.getItem('marinesabres_language')
```
Should return: "fr" (or your selected language)

**Check 4:** Clear browser cache:
- Press Ctrl+Shift+Delete
- Clear "Cached images and files"
- Reload page

**Check 5:** Try direct URL:
- Type: `http://localhost:3838?language=fr`
- If this works but Settings doesn't, JavaScript issue

---

### Language Doesn't Persist

**Check:** localStorage in browser console:
```javascript
localStorage.getItem('marinesabres_language')
```

If returns `null`:
- localStorage not saving
- Check browser privacy settings
- Try different browser

---

### Errors in Console

**Look for:**
- "ReferenceError: $ is not defined" → jQuery not loaded
- "Uncaught TypeError" → JavaScript syntax error
- "Failed to load resource" → Missing file

**Copy error message** and report it.

---

## 📊 Current Status

### ✅ Implemented Features

- **URL query parameter detection** (`?language=xx`)
- **localStorage persistence** (saves language preference)
- **Automatic redirect** (adds query parameter on language change)
- **Full sidebar translation** (249 translation keys available)
- **7 languages supported** (en, es, fr, de, lt, pt, it)

### 📈 Translation Coverage

| Component | Status | Keys |
|-----------|--------|------|
| **Sidebar Menu** | ✅ Complete | 11 items + tooltips |
| **Quick Actions** | ✅ Complete | 4 items |
| **Entry Point Module** | ✅ Complete | ~72 |
| **Create SES Module** | ✅ Complete | ~54 |
| **Template SES Module** | ✅ Complete | ~29 |
| **Network Metrics** | ✅ Complete | ~60 |
| **ISA Data Entry** | ⏳ Not translated | ~150-200 needed |
| **AI Assistant** | ⏳ Not translated | ~80-100 needed |
| **Other Modules** | ⏳ Not translated | ~300-400 needed |

**Total Available:** 249 keys × 7 languages = 1,743 translations

---

## 📝 Expected Sidebar Translations

### English → Français
- Getting Started → **Commencer**
- Dashboard → **Tableau de bord**
- Create SES Model → **Créer le modèle SES**
- ISA Data Entry → **Entrée de données ISA**
- CLD Visualization → **Visualisation CLD**
- Scenario Builder → **Constructeur de scénarios**
- Analysis Tools → **Outils d'analyse**
- Manage Responses → **Gérer les réponses**
- Project Information → **Informations sur le projet**
- Stakeholder Management → **Gestion des parties prenantes**
- Settings → **Paramètres**

### English → Español
- Getting Started → **Primeros Pasos**
- Dashboard → **Panel de Control**
- Create SES Model → **Crear Modelo SES**
- ISA Data Entry → **Entrada de datos ISA**
- CLD Visualization → **Visualización CLD**
- Scenario Builder → **Constructor de Escenarios**
- Analysis Tools → **Herramientas de Análisis**
- Manage Responses → **Gestionar Respuestas**
- Project Information → **Información del Proyecto**
- Stakeholder Management → **Gestión de Partes Interesadas**
- Settings → **Configuración**

### English → Deutsch
- Getting Started → **Erste Schritte**
- Dashboard → **Armaturenbrett**
- Create SES Model → **SES-Modell erstellen**
- ISA Data Entry → **ISA-Dateneingabe**
- CLD Visualization → **CLD-Visualisierung**
- Scenario Builder → **Szenario-Builder**
- Analysis Tools → **Analysewerkzeuge**
- Manage Responses → **Antworten verwalten**
- Project Information → **Projektinformationen**
- Stakeholder Management → **Stakeholder-Management**
- Settings → **Einstellungen**

---

## ✅ Testing Checklist

Use this checklist while testing:

- [ ] App loads at http://localhost:3838
- [ ] Default language is English
- [ ] Settings icon opens language selection
- [ ] Can select French from dropdown
- [ ] "Apply Changes" button works
- [ ] Page reloads with `?language=fr` in URL
- [ ] Sidebar menu displays in French
- [ ] All 11 menu items translated
- [ ] Tooltips show French text
- [ ] "Quick Actions" section in French
- [ ] Close and reopen browser
- [ ] App automatically loads in French
- [ ] Try changing to Spanish
- [ ] Sidebar displays in Spanish
- [ ] Try direct URL `?language=de`
- [ ] App loads in German
- [ ] No JavaScript errors in console
- [ ] No HTML tags displaying in UI
- [ ] Language changes smoothly
- [ ] No flash of English content

---

## 🎉 Success Criteria

**Fix is working if:**
1. ✅ Sidebar menu translates to selected language
2. ✅ Language persists after closing browser
3. ✅ URL shows `?language=xx` parameter
4. ✅ All 7 languages work correctly
5. ✅ No errors in browser console

**Fix needs adjustment if:**
1. ❌ Sidebar remains in English
2. ❌ Language resets to English after reload
3. ❌ JavaScript errors appear
4. ❌ Some menu items don't translate
5. ❌ HTML tags display instead of text

---

## 📞 Report Results

After testing, please report:

1. **Which tests passed?** (Test 1, 2, 3, 4)
2. **Which languages worked?** (en, es, fr, de, lt, pt, it)
3. **Any errors seen?** (copy from console)
4. **Screenshots if possible** (especially if issues found)

---

*Testing guide created: October 28, 2025*
*App version: 1.2.1*
*Fix type: URL query parameter approach*
*Expected outcome: Full sidebar translation in all 7 languages*
