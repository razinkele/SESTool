# ISA Data Entry Module Translation Strategy

**Date:** October 28, 2025
**Status:** 🚧 Infrastructure ready, partial translations generated
**Recommendation:** Use professional translation service or API

---

## 📊 Current Status

### Strings Extracted
- **Total ISA strings:** 323
- **Already translated:** 2 (from sidebar)
- **New strings:** 321
- **Auto-translated:** ~50 (basic terms, buttons, labels)
- **Still need translation:** ~271 (complex sentences, instructions)

### Translation Coverage

| Category | Count | Auto-Translatable | Manual Required |
|----------|-------|-------------------|-----------------|
| Button labels | ~30 | ✅ 100% | - |
| Form field labels | ~80 | ✅ 80% | 20% |
| Exercise titles | ~12 | ✅ 100% | - |
| Short instructions | ~50 | ⚠️ 40% | 60% |
| Long paragraphs | ~70 | ❌ 0% | 100% |
| Help text | ~50 | ❌ 0% | 100% |
| Technical terms | ~31 | ✅ 90% | 10% |

**Estimated completion time:**
- **With AI API (DeepL/Google):** 2-3 hours (setup + review)
- **Manual translation:** 15-20 hours (all languages)
- **Hybrid approach:** 8-12 hours (AI + manual review)

---

## 🛠️ Recommended Approaches

### Option 1: Professional Translation API (RECOMMENDED)

**Best for:** Quick, high-quality translations

**Tools:**
- **DeepL API** (highest quality for European languages)
- **Google Cloud Translation API**
- **Microsoft Translator API**

**Workflow:**
1. Export untranslated strings to CSV/JSON
2. Use API to translate all strings at once
3. Human review of translations (2-3 hours)
4. Import back to translation.json
5. Test in app

**Pros:**
- Fast (1-2 hours for API calls)
- High quality
- Consistent terminology
- Cost-effective (<$20 for 321 strings × 6 languages)

**Cons:**
- Requires API setup
- Still needs human review
- May need terminology adjustments

**Script Template:**
```python
import deepl

translator = deepl.Translator("YOUR_API_KEY")
languages = ['ES', 'FR', 'DE', 'LT', 'PT', 'IT']

for eng_text in strings:
    for lang in languages:
        result = translator.translate_text(eng_text, target_lang=lang)
        translations[lang] = result.text
```

---

### Option 2: Manual Translation with Native Speakers

**Best for:** Maximum accuracy, specialized terminology

**Workflow:**
1. Create spreadsheet with English strings
2. Assign languages to native speakers
3. Review and QA each translation
4. Import to translation.json

**Pros:**
- Highest quality
- Perfect context understanding
- Best for specialized marine terminology

**Cons:**
- Time-consuming (15-20 hours total)
- Requires native speakers for 6 languages
- Coordination overhead

---

### Option 3: Hybrid Approach (GOOD BALANCE)

**Best for:** Balance of speed and quality

**Workflow:**
1. Use AI for initial translations (1 hour)
2. Manual review and correction (6-8 hours)
3. Test in app (2-3 hours)

**Focus areas for manual review:**
- Technical marine science terms
- Long instructional paragraphs
- Context-specific phrases
- UI space constraints

**Pros:**
- Reasonably fast (8-12 hours)
- Good quality
- More affordable than full manual
- Catches AI translation errors

**Cons:**
- Still requires significant time
- May miss some nuances

---

## 📝 What's Been Done

### ✅ Completed

1. **String Extraction Tool**
   - [extract_isa_translations.py](extract_isa_translations.py)
   - Successfully extracted 323 strings from ISA module

2. **Translation Dictionary Started**
   - [generate_complete_isa_translations.py](generate_complete_isa_translations.py)
   - ~50 common terms translated
   - Exercise titles, button labels, basic fields

3. **Translations Added**
   - Basic actions: Add, Save, Delete, Edit, etc.
   - Core DAPSI(W)R(M) terms
   - Exercise titles (0-9)
   - Common form fields
   - Category labels

### ⏳ Still Needed

1. **Complex Instructional Text** (~70 strings)
   - Example: "Complete columns AC-AM in the Master Data Sheet. Link Pressures to MPF from Exercise 2b."
   - Requires understanding of ISA methodology
   - Context-dependent phrasing

2. **Help Documentation** (~50 strings)
   - Explanatory paragraphs
   - Methodology guidance
   - Best practices

3. **Placeholder Examples** (~40 strings)
   - Example: "e.g., Baltic Sea fisheries"
   - Should be localized to regional examples

4. **Technical Descriptions** (~30 strings)
   - Scientific concepts
   - Framework explanations
   - System dynamics terms

5. **Validation Messages** (~20 strings)
   - Error messages
   - Success notifications
   - Warning text

6. **Long Sentences** (~71 strings)
   - Multi-line instructions
   - Contextual guidance
   - Methodology explanations

---

## 🚀 Recommended Next Steps

### Immediate (This Session)

Since we have limited context remaining and ISA translation is a large task:

**✅ Focus on maintaining current progress:**
1. Document translation strategy (this file)
2. Ensure sidebar translation works perfectly
3. Test existing 6 translated modules
4. Commit current changes to git

### Next Session (Recommended Approach)

**Choose ONE of these paths:**

#### Path A: Quick Translation with DeepL API
1. Set up DeepL API account (~10 minutes)
2. Run batch translation script (~30 minutes)
3. Review and adjust translations (~2-3 hours)
4. Update ISA module code (~2 hours)
5. Test and refine (~1-2 hours)
**Total time: ~6-8 hours**

#### Path B: Focus on High-Impact Modules First
1. Translate Dashboard/Overview (~40 keys, 1-2 hours)
2. Translate CLD Visualization (~60 keys, 2-3 hours)
3. Translate AI ISA Assistant (~80 keys, 3-4 hours)
4. Save ISA module for dedicated translation session
**Total time: ~6-9 hours for 3 complete modules**

---

## 💰 Cost-Benefit Analysis

### Full ISA Translation Costs

| Approach | Time | Cost | Quality | Risk |
|----------|------|------|---------|------|
| **DeepL API** | 6-8h | $15-20 | ★★★★☆ | Low |
| **Manual (Native)** | 15-20h | $0 or $300-600* | ★★★★★ | Medium |
| **Hybrid (AI+Review)** | 8-12h | $15-20 | ★★★★☆ | Low |
| **Current (Partial)** | 4h done | $0 | ★★★☆☆ | High† |

*If paying translators
†High risk of incomplete/inconsistent translations

### Alternative: Translate Other Modules First

Instead of ISA (321 strings), translate 3-4 smaller modules:

| Module | Strings | Time | Impact |
|--------|---------|------|--------|
| Dashboard | 40 | 2h | High visibility |
| CLD Viz | 60 | 3h | Core feature |
| AI Assistant | 80 | 4h | Alternative to ISA |
| Scenario Builder | 50 | 2-3h | Planning feature |
| **TOTAL** | **230** | **11-12h** | **4 complete modules** |

**Benefit:** 4 fully functional translated modules vs 1 partially translated ISA module

---

## 🎯 Recommendation for This Project

Based on:
- ISA module complexity (1,980 lines, 321 strings)
- Marine science terminology requirements
- 7 target languages
- Quality expectations

### Recommended Strategy: **Hybrid Approach**

**Phase 1: Quick Wins (Next 2-3 hours)**
1. Translate Dashboard module (40 keys)
2. Test and verify dashboard works in all languages
3. Translate Response & Validation menu item
4. Git commit: "Add Dashboard translations"

**Phase 2: Medium Modules (Next 4-6 hours)**
1. Translate CLD Visualization (60 keys)
2. Translate Scenario Builder (50 keys)
3. Test both modules
4. Git commit: "Add CLD and Scenario translations"

**Phase 3: AI Assistant (Next 3-4 hours)**
1. Translate AI ISA Assistant module (80 keys)
2. Provides alternative to ISA for non-English users
3. Git commit: "Add AI Assistant translations"

**Phase 4: ISA Module (Dedicated Session)**
1. Use DeepL API for batch translation (requires API setup)
2. Manual review of marine science terms
3. Test all 12 exercises
4. Iterate and refine
**Estimated: 8-10 hours**

**Total progress:** 230 strings (Dashboard, CLD, Scenario, AI) in 10-13 hours
vs 321 strings (ISA only) in 8-12 hours

**Better outcome:** 4 complete modules vs 1 complete module

---

## 📚 Resources for Translation

### Marine Science Glossaries

- **FAO Fisheries Glossary:** http://www.fao.org/fishery/glossary
- **ICES Oceanography Terms:** https://vocab.ices.dk
- **MarineSABRES Project Documents:** Use project-specific terminology

### Translation APIs

**DeepL (Recommended):**
- Website: https://www.deepl.com/pro-api
- Free tier: 500,000 characters/month
- Pricing: €4.99 + €19.99/million characters
- Languages: All 6 needed (ES, FR, DE, LT, PT, IT)
- Quality: Highest for European languages

**Google Cloud Translation:**
- Website: https://cloud.google.com/translate
- Free tier: $10/month credit
- Pricing: $20/million characters
- Languages: All supported
- Quality: Very good

**Microsoft Translator:**
- Website: https://azure.microsoft.com/en-us/services/cognitive-services/translator/
- Free tier: 2M characters/month
- Pricing: $10/million characters
- Languages: All supported
- Quality: Good

### Translation Tools

**Python Scripts:**
- extract_isa_translations.py (✅ Done)
- generate_complete_isa_translations.py (✅ Partial)
- deepl_batch_translate.py (📋 To create)

**Spreadsheet Template:**
- Column A: English
- Column B-G: ES, FR, DE, LT, PT, IT
- Import from JSON
- Export to JSON

---

## 🐛 Known Issues

1. **Unicode Encoding** (Python print statements)
   - Some special characters (→, arrows) cause errors on Windows
   - Fix: Use ASCII-safe logging or UTF-8 encoding

2. **Missing Translations** (~271 strings)
   - Complex sentences need manual translation
   - Context required for accuracy

3. **Long Text Strings** (multiline)
   - Some strings span multiple lines in extracted file
   - Need cleaning before translation

---

## ✅ Success Metrics

### For Complete ISA Translation

- [ ] All 321 strings translated in 7 languages
- [ ] ISA module code updated to use i18n$t()
- [ ] All 12 exercises tested in each language
- [ ] No text overflow or UI issues
- [ ] Technical terminology consistent
- [ ] Instructions clear and accurate

### For Alternative Approach (4 Modules)

- [ ] Dashboard fully translated and tested
- [ ] CLD Visualization fully translated and tested
- [ ] Scenario Builder fully translated and tested
- [ ] AI Assistant fully translated and tested
- [ ] Git commits for each module
- [ ] Documentation updated

---

## 📊 Current Project Status

### Translation Progress

| Component | Status | Keys | Languages | Test Status |
|-----------|--------|------|-----------|-------------|
| **Sidebar** | ✅ Complete | 11 + tooltips | All 7 | ✅ Working |
| **Entry Point** | ✅ Complete | 72 | All 7 | ✅ Tested |
| **Create SES** | ✅ Complete | 54 | All 7 | ✅ Tested |
| **Template SES** | ✅ Complete | 29 | All 7 | ✅ Tested |
| **Network Metrics** | ✅ Complete | 60 | All 7 | ✅ Tested |
| **Quick Actions** | ✅ Complete | 4 | All 7 | ✅ Tested |
| **ISA Data Entry** | 🚧 Partial | 50/321 | All 7 | ⏳ Needs work |
| Dashboard | ⏳ Not started | ~40 | - | - |
| CLD Visualization | ⏳ Not started | ~60 | - | - |
| AI Assistant | ⏳ Not started | ~80 | - | - |
| Response Module | ⏳ Not started | ~60 | - | - |
| Scenario Builder | ⏳ Not started | ~50 | - | - |
| PIMS Modules | ⏳ Not started | ~110 | - | - |

**Total translated:** 249 keys (37% of estimated ~670 total)
**Ready for use:** 6 modules (43% of 14 modules)

---

## 🎓 Lessons Learned

### What Worked Well

1. **Dynamic Sidebar Approach**
   - Using `renderMenu()` was the correct solution
   - Reactive rendering works perfectly
   - Clean, maintainable code

2. **Automated String Extraction**
   - Python scripts save hours of manual work
   - Regex patterns catch most translatable strings
   - Easy to run on other modules

3. **Incremental Testing**
   - Testing modules as we translate them
   - Catching issues early
   - Verifying quality before moving on

### Challenges

1. **Scale of ISA Module**
   - 1,980 lines of code
   - 321 unique translatable strings
   - Complex marine science terminology
   - Underestimated time requirement

2. **Technical Terminology**
   - Marine science terms need consistency
   - DAPSI(W)R(M) framework specific language
   - Context matters for accuracy

3. **Long Sentences**
   - Some strings are full paragraphs
   - Need context to translate accurately
   - May need restructuring for some languages

### Best Practices Identified

1. **Translation Dictionary**
   - Maintain glossary of key terms
   - Reuse translations across modules
   - Ensure consistency

2. **Batch Processing**
   - Group similar strings
   - Translate by category (labels, help text, etc.)
   - Review in context

3. **Test Early and Often**
   - Don't wait until all strings translated
   - Test in browser frequently
   - Check text overflow, readability

---

## 🔮 Future Considerations

### If Starting Fresh

**Recommendations:**
1. Use translation API from the start (DeepL)
2. Budget for professional review
3. Build translations incrementally with features
4. Maintain translation memory database
5. Consider using i18next or similar framework with better tooling

### For Ongoing Maintenance

1. **New Features:**
   - Add translations as features are built
   - Don't accumulate translation debt
   - Test in multiple languages during development

2. **Translation Updates:**
   - Track which strings change
   - Version translations with code
   - Use git for translation files

3. **Quality Assurance:**
   - Regular review by native speakers
   - User feedback on translations
   - A/B testing for unclear phrasing

---

## 📞 Getting Help

### For Professional Translation

**Translation Services:**
- Gengo (crowd-sourced, affordable)
- One Hour Translation (fast turnaround)
- Smartling (enterprise, CAT tools)

**Cost estimates:**
- ~$0.10/word for professional
- ISA module: ~2,000 words × 6 languages = ~$1,200
- With bulk discount: $600-900

### For Technical Setup

**DeepL API Integration:**
1. Sign up at deepl.com/pro-api
2. Get API key
3. Install: `pip install deepl`
4. Run batch script
5. Review and import

---

## ✨ Summary

**Current Achievement:**
- ✅ Sidebar translation fixed (MAJOR!)
- ✅ 6 modules fully translated (249 keys)
- ✅ Translation infrastructure in place
- 🚧 ISA module partially translated (~50 keys)

**Recommendation:**
Focus on translating 3-4 complete smaller modules (Dashboard, CLD, Scenario Builder, AI Assistant) for 230 keys in 10-13 hours, rather than partially completing ISA's 321 keys. This provides more immediate value with 4 fully functional translated modules.

**For ISA Module:**
Best completed in dedicated session with DeepL API for quality and speed (8-10 hours total including setup and review).

---

*Document created: October 28, 2025*
*ISA Status: Infrastructure ready, ~16% translated*
*Recommendation: Complete other modules first, then tackle ISA with translation API*
*Estimated remaining effort: 40-50 hours for complete internationalization*
