library(jsonlite)

pims <- fromJSON('pims_module_translations.json')
ai <- fromJSON('ai_isa_assistant_module_translations.json')
sh <- fromJSON('pims_stakeholder_module_translations.json')

cat('PIMS module:', length(pims$translation), 'keys\n')
cat('AI ISA Assistant:', length(ai$translation), 'keys\n')
cat('PIMS Stakeholder:', length(sh$translation), 'keys\n')
cat('TOTAL:', length(pims$translation) + length(ai$translation) + length(sh$translation), 'keys\n')
