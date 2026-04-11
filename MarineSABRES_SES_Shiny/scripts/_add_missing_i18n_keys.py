#!/usr/bin/env python3
"""Add missing i18n keys discovered in the 2026-04-11 audit."""
import json
from pathlib import Path

KEYS = {
    "translations/modules/isa_data_entry.json": {
        "modules.isa.ai_assistant.no_elements_yet": {
            "en": "I notice you haven't added any elements yet!",
            "es": "¡He notado que aún no has añadido elementos!",
            "fr": "Je remarque que vous n'avez encore ajouté aucun élément !",
            "de": "Ich sehe, dass Sie noch keine Elemente hinzugefügt haben!",
            "lt": "Pastebiu, kad dar nepridėjote jokių elementų!",
            "pt": "Notei que você ainda não adicionou nenhum elemento!",
            "it": "Noto che non hai ancora aggiunto alcun elemento!",
            "no": "Jeg ser at du ikke har lagt til noen elementer ennå!",
            "el": "Παρατηρώ ότι δεν έχετε προσθέσει ακόμα στοιχεία!"
        },
        "modules.isa.ai_assistant.elements_added_with_count": {
            "en": "I see you've added %d elements, but I couldn't generate connections between them. I've identified %d potential pathways.",
            "es": "Veo que has añadido %d elementos, pero no pude generar conexiones entre ellos. He identificado %d caminos potenciales.",
            "fr": "Je vois que vous avez ajouté %d éléments, mais je n'ai pas pu générer de connexions entre eux. J'ai identifié %d voies potentielles.",
            "de": "Sie haben %d Elemente hinzugefügt, aber ich konnte keine Verbindungen zwischen ihnen erzeugen. Ich habe %d mögliche Pfade identifiziert.",
            "lt": "Matau, kad pridėjote %d elementų, bet negalėjau sukurti ryšių tarp jų. Identifikavau %d galimus kelius.",
            "pt": "Vejo que você adicionou %d elementos, mas não consegui gerar conexões entre eles. Identifiquei %d caminhos potenciais.",
            "it": "Vedo che hai aggiunto %d elementi, ma non sono riuscito a generare connessioni tra di loro. Ho identificato %d percorsi potenziali.",
            "no": "Jeg ser at du har lagt til %d elementer, men jeg kunne ikke generere forbindelser mellom dem. Jeg har identifisert %d potensielle veier.",
            "el": "Βλέπω ότι έχετε προσθέσει %d στοιχεία, αλλά δεν μπόρεσα να δημιουργήσω συνδέσεις μεταξύ τους. Έχω εντοπίσει %d πιθανές διαδρομές."
        },
        "modules.isa.ai_assistant.completion_message": {
            "en": "Excellent work! You've completed your DAPSI(W)R(M) model with connections. Review the summary on the right, and when ready, click 'Save to ISA Data Entry' to transfer your model to the main ISA module.",
            "es": "¡Excelente trabajo! Has completado tu modelo DAPSI(W)R(M) con conexiones. Revisa el resumen a la derecha y, cuando estés listo, haz clic en 'Guardar en Entrada de Datos ISA'.",
            "fr": "Excellent travail ! Vous avez complété votre modèle DAPSI(W)R(M) avec les connexions. Passez en revue le résumé à droite et, lorsque vous êtes prêt, cliquez sur 'Enregistrer dans la saisie de données ISA'.",
            "de": "Ausgezeichnete Arbeit! Sie haben Ihr DAPSI(W)R(M)-Modell mit Verbindungen vervollständigt. Überprüfen Sie die Zusammenfassung rechts und klicken Sie, wenn Sie bereit sind, auf 'In ISA-Dateneingabe speichern'.",
            "lt": "Puikus darbas! Užbaigėte savo DAPSI(W)R(M) modelį su ryšiais. Peržiūrėkite suvestinę dešinėje ir, kai būsite pasirengę, spustelėkite 'Išsaugoti į ISA duomenų įvedimą'.",
            "pt": "Excelente trabalho! Você completou seu modelo DAPSI(W)R(M) com conexões. Revise o resumo à direita e, quando estiver pronto, clique em 'Salvar em Entrada de Dados ISA'.",
            "it": "Ottimo lavoro! Hai completato il tuo modello DAPSI(W)R(M) con le connessioni. Rivedi il riepilogo a destra e, quando sei pronto, clicca 'Salva in Inserimento Dati ISA'.",
            "no": "Utmerket arbeid! Du har fullført DAPSI(W)R(M)-modellen din med tilkoblinger. Gjennomgå sammendraget til høyre og klikk 'Lagre til ISA-dataregistrering' når du er klar.",
            "el": "Εξαιρετική δουλειά! Ολοκληρώσατε το μοντέλο DAPSI(W)R(M) με συνδέσεις. Ελέγξτε τη σύνοψη στα δεξιά και όταν είστε έτοιμοι, κάντε κλικ στο 'Αποθήκευση στην Καταχώρηση Δεδομένων ISA'."
        },
        "modules.isa.ai_assistant.general_marine_suggestions": {
            "en": "I'll use general marine suggestions for your area.",
            "es": "Usaré sugerencias marinas generales para tu área.",
            "fr": "J'utiliserai des suggestions marines générales pour votre zone.",
            "de": "Ich werde allgemeine Meeresvorschläge für Ihre Region verwenden.",
            "lt": "Naudosiu bendras jūrines nuorodas jūsų vietovei.",
            "pt": "Usarei sugestões marinhas gerais para sua área.",
            "it": "Userò suggerimenti marini generali per la tua area.",
            "no": "Jeg vil bruke generelle marine forslag for området ditt.",
            "el": "Θα χρησιμοποιήσω γενικές θαλάσσιες προτάσεις για την περιοχή σας."
        },
        "modules.isa.ai_assistant.ecosystem_unique_characteristics": {
            "en": "%s ecosystems have unique characteristics that I'll consider in my suggestions.",
            "es": "Los ecosistemas %s tienen características únicas que consideraré en mis sugerencias.",
            "fr": "Les écosystèmes %s ont des caractéristiques uniques que je prendrai en compte dans mes suggestions.",
            "de": "%s-Ökosysteme haben einzigartige Eigenschaften, die ich in meinen Vorschlägen berücksichtigen werde.",
            "lt": "%s ekosistemos turi unikalias savybes, į kurias atsižvelgsiu savo pasiūlymuose.",
            "pt": "Os ecossistemas %s têm características únicas que considerarei em minhas sugestões.",
            "it": "Gli ecosistemi %s hanno caratteristiche uniche che prenderò in considerazione nei miei suggerimenti.",
            "no": "%s-økosystemer har unike egenskaper som jeg vil ta hensyn til i forslagene mine.",
            "el": "Τα οικοσυστήματα %s έχουν μοναδικά χαρακτηριστικά που θα λάβω υπόψη στις προτάσεις μου."
        },
        "modules.isa.ai_assistant.focus_on_issue": {
            "en": "Understood. I'll focus suggestions on %s.",
            "es": "Entendido. Centraré las sugerencias en %s.",
            "fr": "Compris. Je concentrerai les suggestions sur %s.",
            "de": "Verstanden. Ich werde die Vorschläge auf %s konzentrieren.",
            "lt": "Supratau. Pasiūlymus sutelksiu į %s.",
            "pt": "Entendido. Focarei as sugestões em %s.",
            "it": "Capito. Concentrerò i suggerimenti su %s.",
            "no": "Forstått. Jeg vil fokusere forslagene på %s.",
            "el": "Κατανοητό. Θα επικεντρώσω τις προτάσεις στο %s."
        },
        "modules.isa.ai_assistant.start_building_framework": {
            "en": "Now let's start building your DAPSI(W)R(M) framework!",
            "es": "¡Ahora comencemos a construir tu marco DAPSI(W)R(M)!",
            "fr": "Commençons maintenant à construire votre cadre DAPSI(W)R(M) !",
            "de": "Lassen Sie uns jetzt Ihren DAPSI(W)R(M)-Rahmen aufbauen!",
            "lt": "Dabar pradėkime kurti jūsų DAPSI(W)R(M) sistemą!",
            "pt": "Agora vamos começar a construir seu framework DAPSI(W)R(M)!",
            "it": "Ora iniziamo a costruire il tuo framework DAPSI(W)R(M)!",
            "no": "La oss nå begynne å bygge DAPSI(W)R(M)-rammeverket ditt!",
            "el": "Τώρα ας αρχίσουμε να χτίζουμε το πλαίσιο DAPSI(W)R(M) σας!"
        },
        "modules.isa.ai_assistant.work_auto_saved_navigate": {
            "en": "Your work is already saved automatically. Navigate to 'ISA Data Entry' to see your elements.",
            "es": "Tu trabajo ya está guardado automáticamente. Navega a 'Entrada de Datos ISA' para ver tus elementos.",
            "fr": "Votre travail est déjà enregistré automatiquement. Accédez à 'Saisie de données ISA' pour voir vos éléments.",
            "de": "Ihre Arbeit wird bereits automatisch gespeichert. Navigieren Sie zu 'ISA-Dateneingabe', um Ihre Elemente zu sehen.",
            "lt": "Jūsų darbas jau automatiškai išsaugotas. Eikite į 'ISA duomenų įvedimas', kad pamatytumėte savo elementus.",
            "pt": "Seu trabalho já está salvo automaticamente. Navegue para 'Entrada de Dados ISA' para ver seus elementos.",
            "it": "Il tuo lavoro è già salvato automaticamente. Vai su 'Inserimento Dati ISA' per vedere i tuoi elementi.",
            "no": "Arbeidet ditt er allerede lagret automatisk. Naviger til 'ISA-dataregistrering' for å se elementene dine.",
            "el": "Η εργασία σας έχει ήδη αποθηκευτεί αυτόματα. Μεταβείτε στην 'Καταχώρηση Δεδομένων ISA' για να δείτε τα στοιχεία σας."
        },
        "modules.isa.ai_assistant.model_saved_navigate": {
            "en": "Model saved! Navigate to 'ISA Data Entry' to see your elements.",
            "es": "¡Modelo guardado! Navega a 'Entrada de Datos ISA' para ver tus elementos.",
            "fr": "Modèle enregistré ! Accédez à 'Saisie de données ISA' pour voir vos éléments.",
            "de": "Modell gespeichert! Navigieren Sie zu 'ISA-Dateneingabe', um Ihre Elemente zu sehen.",
            "lt": "Modelis išsaugotas! Eikite į 'ISA duomenų įvedimas', kad pamatytumėte savo elementus.",
            "pt": "Modelo salvo! Navegue para 'Entrada de Dados ISA' para ver seus elementos.",
            "it": "Modello salvato! Vai su 'Inserimento Dati ISA' per vedere i tuoi elementi.",
            "no": "Modell lagret! Naviger til 'ISA-dataregistrering' for å se elementene dine.",
            "el": "Το μοντέλο αποθηκεύτηκε! Μεταβείτε στην 'Καταχώρηση Δεδομένων ISA' για να δείτε τα στοιχεία σας."
        },
        "modules.isa.data_entry.welfare_impacts_prompt": {
            "en": "List key impacts on human welfare you've observed...",
            "es": "Enumera los impactos clave en el bienestar humano que has observado...",
            "fr": "Énumérez les impacts clés sur le bien-être humain que vous avez observés...",
            "de": "Listen Sie die wichtigsten Auswirkungen auf das menschliche Wohlergehen auf, die Sie beobachtet haben...",
            "lt": "Išvardykite pagrindinius poveikius žmonių gerovei, kuriuos pastebėjote...",
            "pt": "Liste os principais impactos no bem-estar humano que você observou...",
            "it": "Elenca i principali impatti sul benessere umano che hai osservato...",
            "no": "Liste viktige konsekvenser for menneskers velferd du har observert...",
            "el": "Αναφέρετε τις κύριες επιπτώσεις στην ανθρώπινη ευημερία που έχετε παρατηρήσει..."
        }
    },
    "translations/modules/analysis_tools.json": {
        "modules.analysis.metrics.complete_ses_first": {
            "en": "Navigate to 'ISA Data Entry' and complete your SES model",
            "es": "Navega a 'Entrada de Datos ISA' y completa tu modelo SES",
            "fr": "Accédez à 'Saisie de données ISA' et complétez votre modèle SES",
            "de": "Navigieren Sie zu 'ISA-Dateneingabe' und vervollständigen Sie Ihr SES-Modell",
            "lt": "Eikite į 'ISA duomenų įvedimas' ir užbaikite savo SES modelį",
            "pt": "Navegue para 'Entrada de Dados ISA' e complete seu modelo SES",
            "it": "Vai su 'Inserimento Dati ISA' e completa il tuo modello SES",
            "no": "Naviger til 'ISA-dataregistrering' og fullfør SES-modellen din",
            "el": "Μεταβείτε στην 'Καταχώρηση Δεδομένων ISA' και ολοκληρώστε το μοντέλο SES σας"
        },
        "modules.analysis.metrics.generate_cld_first": {
            "en": "Go to 'CLD Visualization' and click 'Generate CLD'",
            "es": "Ve a 'Visualización CLD' y haz clic en 'Generar CLD'",
            "fr": "Allez à 'Visualisation CLD' et cliquez sur 'Générer CLD'",
            "de": "Gehen Sie zu 'CLD-Visualisierung' und klicken Sie auf 'CLD erzeugen'",
            "lt": "Eikite į 'CLD vizualizacija' ir spustelėkite 'Generuoti CLD'",
            "pt": "Vá para 'Visualização CLD' e clique em 'Gerar CLD'",
            "it": "Vai su 'Visualizzazione CLD' e clicca 'Genera CLD'",
            "no": "Gå til 'CLD-visualisering' og klikk 'Generer CLD'",
            "el": "Μεταβείτε στην 'Οπτικοποίηση CLD' και κάντε κλικ στο 'Δημιουργία CLD'"
        },
        "modules.analysis.metrics.pagerank_description": {
            "en": "Google's algorithm: importance based on quality and quantity of incoming connections.",
            "es": "Algoritmo de Google: importancia basada en la calidad y cantidad de conexiones entrantes.",
            "fr": "Algorithme de Google : importance basée sur la qualité et la quantité des connexions entrantes.",
            "de": "Googles Algorithmus: Wichtigkeit basierend auf Qualität und Quantität eingehender Verbindungen.",
            "lt": "Google algoritmas: svarba pagrįsta įeinančių ryšių kokybe ir kiekiu.",
            "pt": "Algoritmo do Google: importância baseada na qualidade e quantidade de conexões de entrada.",
            "it": "Algoritmo di Google: importanza basata sulla qualità e quantità di connessioni in entrata.",
            "no": "Googles algoritme: viktighet basert på kvalitet og kvantitet av innkommende tilkoblinger.",
            "el": "Αλγόριθμος της Google: σημασία βάσει ποιότητας και ποσότητας εισερχόμενων συνδέσεων."
        },
        "modules.analysis.leverage.pagerank_description": {
            "en": "PageRank: Google's algorithm adapted for network analysis. Measures overall importance considering both direct connections and the importance of connecting nodes.",
            "es": "PageRank: Algoritmo de Google adaptado para análisis de redes. Mide la importancia general considerando tanto las conexiones directas como la importancia de los nodos conectados.",
            "fr": "PageRank : Algorithme de Google adapté pour l'analyse de réseau. Mesure l'importance globale en tenant compte des connexions directes et de l'importance des nœuds de connexion.",
            "de": "PageRank: Googles Algorithmus angepasst für Netzwerkanalyse. Misst die Gesamtbedeutung unter Berücksichtigung direkter Verbindungen und der Bedeutung verbindender Knoten.",
            "lt": "PageRank: Google algoritmas pritaikytas tinklo analizei. Matuoja bendrą svarbą atsižvelgiant tiek į tiesioginius ryšius, tiek į jungiančių mazgų svarbą.",
            "pt": "PageRank: Algoritmo do Google adaptado para análise de rede. Mede a importância geral considerando tanto as conexões diretas quanto a importância dos nós conectores.",
            "it": "PageRank: Algoritmo di Google adattato per l'analisi di rete. Misura l'importanza complessiva considerando sia le connessioni dirette che l'importanza dei nodi di connessione.",
            "no": "PageRank: Googles algoritme tilpasset nettverksanalyse. Måler samlet viktighet ved å vurdere både direkte tilkoblinger og viktigheten av tilkoblingsnoder.",
            "el": "PageRank: Αλγόριθμος της Google προσαρμοσμένος για ανάλυση δικτύου. Μετρά τη συνολική σημασία λαμβάνοντας υπόψη τόσο τις άμεσες συνδέσεις όσο και τη σημασία των συνδετικών κόμβων."
        },
        "modules.analysis.leverage.eigenvector_description": {
            "en": "High Eigenvector: Target nodes that are influential because they're connected to other influential nodes.",
            "es": "Eigenvector alto: Nodos objetivo que son influyentes porque están conectados a otros nodos influyentes.",
            "fr": "Vecteur propre élevé : Nœuds cibles influents car connectés à d'autres nœuds influents.",
            "de": "Hoher Eigenvektor: Zielknoten, die einflussreich sind, weil sie mit anderen einflussreichen Knoten verbunden sind.",
            "lt": "Aukšta savivektoriaus reikšmė: tiksliniai mazgai, kurie yra įtakingi, nes yra sujungti su kitais įtakingais mazgais.",
            "pt": "Autovetor alto: Nós alvo que são influentes porque estão conectados a outros nós influentes.",
            "it": "Autovettore alto: Nodi target che sono influenti perché connessi ad altri nodi influenti.",
            "no": "Høy egenvektor: Mål-noder som er innflytelsesrike fordi de er koblet til andre innflytelsesrike noder.",
            "el": "Υψηλός ιδιοδιάνυσμα: Κόμβοι-στόχοι που είναι επιρροής επειδή συνδέονται με άλλους κόμβους επιρροής."
        }
    },
    "translations/modules/template_ses_module.json": {
        "modules.template.selected_message": {
            "en": "Template '%s' selected",
            "es": "Plantilla '%s' seleccionada",
            "fr": "Modèle '%s' sélectionné",
            "de": "Vorlage '%s' ausgewählt",
            "lt": "Šablonas '%s' pasirinktas",
            "pt": "Modelo '%s' selecionado",
            "it": "Modello '%s' selezionato",
            "no": "Mal '%s' valgt",
            "el": "Επιλέχθηκε το πρότυπο '%s'"
        },
        "modules.template.select_to_preview": {
            "en": "Select a template and click 'Review' to preview connections",
            "es": "Selecciona una plantilla y haz clic en 'Revisar' para previsualizar conexiones",
            "fr": "Sélectionnez un modèle et cliquez sur 'Réviser' pour prévisualiser les connexions",
            "de": "Wählen Sie eine Vorlage und klicken Sie auf 'Überprüfen', um Verbindungen anzuzeigen",
            "lt": "Pasirinkite šabloną ir spustelėkite 'Peržiūrėti', kad matytumėte ryšius",
            "pt": "Selecione um modelo e clique em 'Revisar' para visualizar conexões",
            "it": "Seleziona un modello e clicca 'Revisione' per visualizzare le connessioni",
            "no": "Velg en mal og klikk 'Gjennomgå' for å forhåndsvise tilkoblinger",
            "el": "Επιλέξτε ένα πρότυπο και κάντε κλικ στο 'Αναθεώρηση' για προεπισκόπηση συνδέσεων"
        },
        "modules.template.or_load_directly": {
            "en": "Or click 'Load' to load it as-is without review",
            "es": "O haz clic en 'Cargar' para cargarlo tal cual sin revisar",
            "fr": "Ou cliquez sur 'Charger' pour le charger tel quel sans révision",
            "de": "Oder klicken Sie auf 'Laden', um es ohne Überprüfung zu laden",
            "lt": "Arba spustelėkite 'Įkelti', kad įkeltumėte tokį, koks yra, be peržiūros",
            "pt": "Ou clique em 'Carregar' para carregá-lo como está sem revisão",
            "it": "Oppure clicca 'Carica' per caricarlo così com'è senza revisione",
            "no": "Eller klikk 'Last inn' for å laste det inn som det er uten gjennomgang",
            "el": "Ή κάντε κλικ στο 'Φόρτωση' για φόρτωση χωρίς αναθεώρηση"
        }
    }
}


def add_keys_to_file(file_path: str, new_keys: dict) -> int:
    path = Path(file_path)
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    translations = data.get("translation", {})
    added = 0
    for key, value in new_keys.items():
        if key not in translations:
            translations[key] = value
            added += 1
        else:
            print(f"  SKIP (exists): {key}")

    data["translation"] = translations
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    return added


def main():
    project_root = Path(__file__).parent.parent
    total_added = 0
    for rel_path, keys in KEYS.items():
        full_path = project_root / rel_path
        if not full_path.exists():
            print(f"WARNING: {full_path} not found, skipping")
            continue
        n = add_keys_to_file(str(full_path), keys)
        print(f"{rel_path}: added {n} keys")
        total_added += n
    print(f"\nTotal keys added: {total_added}")


if __name__ == "__main__":
    main()
