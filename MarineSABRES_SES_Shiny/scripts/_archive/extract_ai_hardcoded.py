#!/usr/bin/env python3
"""
Extract hardcoded English strings from AI module and create translation entries.
"""

import json
import re

# Hardcoded strings found in the module with their line numbers
hardcoded_strings = [
    {
        "line": 486,
        "key": "modules.isa.ai_assistant.welcome_message",
        "en": "Hello! I'm your AI assistant for creating a DAPSI(W)R(M) model. Let's start by selecting your regional sea or ocean. This helps me provide relevant suggestions for your area.",
        "es": "¡Hola! Soy tu asistente de IA para crear un modelo DAPSI(W)R(M). Comencemos seleccionando tu mar regional u océano. Esto me ayuda a proporcionar sugerencias relevantes para tu área.",
        "fr": "Bonjour ! Je suis votre assistant IA pour créer un modèle DAPSI(W)R(M). Commençons par sélectionner votre mer régionale ou océan. Cela m'aide à fournir des suggestions pertinentes pour votre zone.",
        "de": "Hallo! Ich bin Ihr KI-Assistent zur Erstellung eines DAPSI(W)R(M)-Modells. Beginnen wir mit der Auswahl Ihres regionalen Meeres oder Ozeans. Dies hilft mir, relevante Vorschläge für Ihr Gebiet zu machen.",
        "lt": "Sveiki! Esu jūsų AI asistentas DAPSI(W)R(M) modeliui kurti. Pradėkime pasirinkdami jūsų regioninę jūrą ar vandenyną. Tai man padeda pateikti aktualius pasiūlymus jūsų rajonui.",
        "pt": "Olá! Sou seu assistente de IA para criar um modelo DAPSI(W)R(M). Vamos começar selecionando seu mar regional ou oceano. Isso me ajuda a fornecer sugestões relevantes para sua área.",
        "it": "Ciao! Sono il tuo assistente AI per creare un modello DAPSI(W)R(M). Iniziamo selezionando il tuo mare regionale o oceano. Questo mi aiuta a fornire suggerimenti pertinenti per la tua area."
    },
    {
        "line": 502,
        "key": "modules.isa.ai_assistant.question_main_issues",
        "en": "What are the main environmental or management issues you're addressing? (Select all that apply)",
        "es": "¿Cuáles son los principales problemas ambientales o de gestión que está abordando? (Seleccione todos los que correspondan)",
        "fr": "Quels sont les principaux problèmes environnementaux ou de gestion que vous abordez ? (Sélectionnez tout ce qui s'applique)",
        "de": "Welche Haupt-Umwelt- oder Managementprobleme behandeln Sie? (Wählen Sie alle zutreffenden aus)",
        "lt": "Kokie pagrindiniai aplinkos ar valdymo klausimai sprendžiami? (Pasirinkite visus tinkamus)",
        "pt": "Quais são os principais problemas ambientais ou de gestão que você está abordando? (Selecione todos os aplicáveis)",
        "it": "Quali sono i principali problemi ambientali o gestionali che stai affrontando? (Seleziona tutti quelli applicabili)"
    },
    {
        "line": 510,
        "key": "modules.isa.ai_assistant.question_drivers",
        "en": "Let's identify the DRIVERS - these are the basic human needs or societal demands driving activities in your area. What are the main societal needs?",
        "es": "Identifiquemos los IMPULSORES: estas son las necesidades humanas básicas o demandas sociales que impulsan las actividades en su área. ¿Cuáles son las principales necesidades sociales?",
        "fr": "Identifions les MOTEURS - ce sont les besoins humains fondamentaux ou les demandes sociétales qui motivent les activités dans votre zone. Quels sont les principaux besoins sociétaux ?",
        "de": "Lassen Sie uns die TREIBER identifizieren - dies sind die grundlegenden menschlichen Bedürfnisse oder gesellschaftlichen Anforderungen, die Aktivitäten in Ihrem Gebiet antreiben. Was sind die wichtigsten gesellschaftlichen Bedürfnisse?",
        "lt": "Identifikuokime VAROMĄSIAS JĖGAS - tai pagrindiniai žmonių poreikiai arba visuomenės poreikiai, skatinantys veiklas jūsų rajone. Kokie pagrindiniai visuomenės poreikiai?",
        "pt": "Vamos identificar os IMPULSIONADORES - estas são as necessidades humanas básicas ou demandas sociais que impulsionam as atividades em sua área. Quais são as principais necessidades sociais?",
        "it": "Identifichiamo i FATTORI TRAINANTI - questi sono i bisogni umani fondamentali o le richieste sociali che guidano le attività nella tua area. Quali sono i principali bisogni sociali?"
    },
    {
        "line": 519,
        "key": "modules.isa.ai_assistant.question_activities",
        "en": "Now let's identify ACTIVITIES - the human actions taken to meet those needs. What activities are happening in your marine area?",
        "es": "Ahora identifiquemos las ACTIVIDADES: las acciones humanas tomadas para satisfacer esas necesidades. ¿Qué actividades están ocurriendo en su área marina?",
        "fr": "Maintenant identifions les ACTIVITÉS - les actions humaines prises pour répondre à ces besoins. Quelles activités se déroulent dans votre zone marine ?",
        "de": "Lassen Sie uns nun AKTIVITÄTEN identifizieren - die menschlichen Handlungen, die unternommen werden, um diese Bedürfnisse zu erfüllen. Welche Aktivitäten finden in Ihrem Meeresgebiet statt?",
        "lt": "Dabar identifikuokime VEIKLAS - žmonių veiksmus, skirtus tiems poreikiams patenkinti. Kokios veiklos vyksta jūsų jūrų rajone?",
        "pt": "Agora vamos identificar ATIVIDADES - as ações humanas tomadas para atender a essas necessidades. Quais atividades estão acontecendo em sua área marinha?",
        "it": "Ora identifichiamo le ATTIVITÀ - le azioni umane intraprese per soddisfare questi bisogni. Quali attività stanno avvenendo nella tua area marina?"
    },
    {
        "line": 573,
        "key": "modules.isa.ai_assistant.connection_review_intro",
        "en": "Great! Now I'll suggest logical connections between the elements you've identified. These connections represent causal relationships in your social-ecological system. You can review and approve/reject each suggestion.",
        "es": "¡Genial! Ahora sugeriré conexiones lógicas entre los elementos que has identificado. Estas conexiones representan relaciones causales en su sistema socio-ecológico. Puede revisar y aprobar/rechazar cada sugerencia.",
        "fr": "Excellent ! Maintenant, je vais suggérer des connexions logiques entre les éléments que vous avez identifiés. Ces connexions représentent des relations causales dans votre système socio-écologique. Vous pouvez examiner et approuver/rejeter chaque suggestion.",
        "de": "Großartig! Jetzt werde ich logische Verbindungen zwischen den von Ihnen identifizierten Elementen vorschlagen. Diese Verbindungen stellen kausale Beziehungen in Ihrem sozial-ökologischen System dar. Sie können jeden Vorschlag überprüfen und genehmigen/ablehnen.",
        "lt": "Puiku! Dabar pasiūlysiu loginius ryšius tarp jūsų nustatytų elementų. Šie ryšiai reiškia priežastinius santykius jūsų socialinėje-ekologinėje sistemoje. Galite peržiūrėti ir patvirtinti/atmesti kiekvieną pasiūlymą.",
        "pt": "Ótimo! Agora vou sugerir conexões lógicas entre os elementos que você identificou. Essas conexões representam relações causais em seu sistema socioecológico. Você pode revisar e aprovar/rejeitar cada sugestão.",
        "it": "Ottimo! Ora suggerirò connessioni logiche tra gli elementi che hai identificato. Queste connessioni rappresentano relazioni causali nel tuo sistema socio-ecologico. Puoi rivedere e approvare/rifiutare ogni suggerimento."
    },
    {
        "line": 867,
        "key": "modules.isa.ai_assistant.previous_session_found",
        "en": "A previous session was found. Click 'Load Saved' to restore it.",
        "es": "Se encontró una sesión anterior. Haga clic en 'Cargar guardado' para restaurarla.",
        "fr": "Une session précédente a été trouvée. Cliquez sur 'Charger enregistré' pour la restaurer.",
        "de": "Eine vorherige Sitzung wurde gefunden. Klicken Sie auf 'Gespeicherte laden', um sie wiederherzustellen.",
        "lt": "Rasta ankstesnė sesija. Spustelėkite 'Įkelti išsaugotą', kad ją atkurtumėte.",
        "pt": "Uma sessão anterior foi encontrada. Clique em 'Carregar salvo' para restaurá-la.",
        "it": "È stata trovata una sessione precedente. Fai clic su 'Carica salvato' per ripristinarla."
    },
    {
        "line": 922,
        "key": "modules.isa.ai_assistant.completion_message",
        "en": "Great work! You've completed all the steps. Review your connections and finalize your model.",
        "es": "¡Buen trabajo! Has completado todos los pasos. Revisa tus conexiones y finaliza tu modelo.",
        "fr": "Excellent travail ! Vous avez terminé toutes les étapes. Examinez vos connexions et finalisez votre modèle.",
        "de": "Großartige Arbeit! Sie haben alle Schritte abgeschlossen. Überprüfen Sie Ihre Verbindungen und finalisieren Sie Ihr Modell.",
        "lt": "Puikus darbas! Užbaigėte visus žingsnius. Peržiūrėkite savo ryšius ir užbaikite modelį.",
        "pt": "Ótimo trabalho! Você completou todas as etapas. Revise suas conexões e finalize seu modelo.",
        "it": "Ottimo lavoro! Hai completato tutti i passaggi. Rivedi le tue connessioni e finalizza il tuo modello."
    },
    {
        "line": 1053,
        "key": "modules.isa.ai_assistant.great_youve_approved",
        "en": "Great! You've approved",
        "es": "¡Genial! Has aprobado",
        "fr": "Excellent ! Vous avez approuvé",
        "de": "Großartig! Sie haben genehmigt",
        "lt": "Puiku! Patvirtinote",
        "pt": "Ótimo! Você aprovou",
        "it": "Ottimo! Hai approvato"
    },
    {
        "line": 1857,
        "key": "modules.isa.ai_assistant.ecosystems_unique_characteristics",
        "en": "ecosystems have unique characteristics that I'll consider in my suggestions.",
        "es": "los ecosistemas tienen características únicas que consideraré en mis sugerencias.",
        "fr": "les écosystèmes ont des caractéristiques uniques que je prendrai en compte dans mes suggestions.",
        "de": "Ökosysteme haben einzigartige Eigenschaften, die ich in meinen Vorschlägen berücksichtigen werde.",
        "lt": "ekosistemos turi unikalias savybes, kurias atsižvelgsiu į savo pasiūlymus.",
        "pt": "os ecossistemas têm características únicas que considerarei em minhas sugestões.",
        "it": "gli ecosistemi hanno caratteristiche uniche che prenderò in considerazione nei miei suggerimenti."
    },
    {
        "line": 1940,
        "key": "modules.isa.ai_assistant.understood_focus_suggestions",
        "en": "Understood. I'll focus suggestions on",
        "es": "Entendido. Centraré las sugerencias en",
        "fr": "Compris. Je concentrerai les suggestions sur",
        "de": "Verstanden. Ich werde die Vorschläge konzentrieren auf",
        "lt": "Supratau. Sutelksiu pasiūlymus į",
        "pt": "Entendido. Focarei as sugestões em",
        "it": "Capito. Concentrerò i suggerimenti su"
    },
    {
        "line": 1941,
        "key": "modules.isa.ai_assistant.now_lets_start_building",
        "en": "Now let's start building your DAPSI(W)R(M) framework!",
        "es": "¡Ahora comencemos a construir tu marco DAPSI(W)R(M)!",
        "fr": "Maintenant, commençons à construire votre cadre DAPSI(W)R(M) !",
        "de": "Jetzt beginnen wir mit dem Aufbau Ihres DAPSI(W)R(M)-Rahmens!",
        "lt": "Dabar pradėkime kurti jūsų DAPSI(W)R(M) sistemą!",
        "pt": "Agora vamos começar a construir sua estrutura DAPSI(W)R(M)!",
        "it": "Ora iniziamo a costruire il tuo framework DAPSI(W)R(M)!"
    },
    {
        "line": 2058,
        "key": "modules.isa.ai_assistant.great_focus_on_issues",
        "en": "Great! I'll focus suggestions on these issues:",
        "es": "¡Genial! Centraré las sugerencias en estos temas:",
        "fr": "Excellent ! Je concentrerai les suggestions sur ces problèmes :",
        "de": "Großartig! Ich werde die Vorschläge auf diese Themen konzentrieren:",
        "lt": "Puiku! Sutelksiu pasiūlymus į šias problemas:",
        "pt": "Ótimo! Focarei as sugestões nesses problemas:",
        "it": "Ottimo! Concentrerò i suggerimenti su questi problemi:"
    }
]

print(f"Creating {len(hardcoded_strings)} translation entries...")

# Save to JSON
with open('/tmp/ai_hardcoded_translations.json', 'w', encoding='utf-8') as f:
    json.dump(hardcoded_strings, f, indent=2, ensure_ascii=False)

print(f"✓ Saved to /tmp/ai_hardcoded_translations.json")
print(f"\nKeys created:")
for item in hardcoded_strings:
    print(f"  - {item['key']}")

