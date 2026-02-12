#!/usr/bin/env python3
"""
Add Greek (EL) translations to all translation files.
Uses a dictionary of common terms and transliterates/keeps English for technical terms.
"""

import json
import os
import re

# Greek translations for common terms
GREEK_TRANSLATIONS = {
    # Common UI terms
    'save': 'Αποθήκευση',
    'cancel': 'Ακύρωση',
    'close': 'Κλείσιμο',
    'confirm': 'Επιβεβαίωση',
    'delete': 'Διαγραφή',
    'edit': 'Επεξεργασία',
    'add': 'Προσθήκη',
    'remove': 'Αφαίρεση',
    'yes': 'Ναι',
    'no': 'Όχι',
    'ok': 'Εντάξει',
    'start': 'Έναρξη',
    'stop': 'Διακοπή',
    'next': 'Επόμενο',
    'previous': 'Προηγούμενο',
    'back': 'Πίσω',
    'forward': 'Μπροστά',
    'submit': 'Υποβολή',
    'reset': 'Επαναφορά',
    'clear': 'Καθαρισμός',
    'export': 'Εξαγωγή',
    'import': 'Εισαγωγή',
    'download': 'Λήψη',
    'upload': 'Μεταφόρτωση',
    'settings': 'Ρυθμίσεις',
    'options': 'Επιλογές',
    'help': 'Βοήθεια',
    'info': 'Πληροφορίες',
    'information': 'Πληροφορίες',
    'error': 'Σφάλμα',
    'warning': 'Προειδοποίηση',
    'success': 'Επιτυχία',
    'failed': 'Απέτυχε',
    'loading': 'Φόρτωση',
    'processing': 'Επεξεργασία',
    'please wait': 'Παρακαλώ περιμένετε',
    'search': 'Αναζήτηση',
    'filter': 'Φίλτρο',
    'sort': 'Ταξινόμηση',
    'select': 'Επιλογή',
    'selected': 'Επιλεγμένο',
    'all': 'Όλα',
    'none': 'Κανένα',
    'total': 'Σύνολο',
    'count': 'Αριθμός',
    'name': 'Όνομα',
    'title': 'Τίτλος',
    'description': 'Περιγραφή',
    'type': 'Τύπος',
    'status': 'Κατάσταση',
    'date': 'Ημερομηνία',
    'time': 'Ώρα',
    'created': 'Δημιουργήθηκε',
    'modified': 'Τροποποιήθηκε',
    'updated': 'Ενημερώθηκε',
    'version': 'Έκδοση',
    'language': 'Γλώσσα',
    'user': 'Χρήστης',
    'users': 'Χρήστες',
    'role': 'Ρόλος',
    'permission': 'Άδεια',
    'view': 'Προβολή',
    'preview': 'Προεπισκόπηση',
    'details': 'Λεπτομέρειες',
    'summary': 'Περίληψη',
    'overview': 'Επισκόπηση',
    'dashboard': 'Πίνακας ελέγχου',
    'home': 'Αρχική',
    'menu': 'Μενού',
    'file': 'Αρχείο',
    'folder': 'Φάκελος',
    'project': 'Έργο',
    'template': 'Πρότυπο',
    'report': 'Αναφορά',
    'analysis': 'Ανάλυση',
    'results': 'Αποτελέσματα',
    'data': 'Δεδομένα',
    'input': 'Είσοδος',
    'output': 'Έξοδος',
    'value': 'Τιμή',
    'values': 'Τιμές',
    'required': 'Απαιτείται',
    'optional': 'Προαιρετικό',
    'default': 'Προεπιλογή',
    'custom': 'Προσαρμοσμένο',
    'new': 'Νέο',
    'create': 'Δημιουργία',
    'update': 'Ενημέρωση',
    'apply': 'Εφαρμογή',
    'finish': 'Ολοκλήρωση',
    'complete': 'Ολοκληρώθηκε',
    'continue': 'Συνέχεια',
    'skip': 'Παράλειψη',
    'retry': 'Επανάληψη',
    'refresh': 'Ανανέωση',
    'reload': 'Επαναφόρτωση',
    'restore': 'Επαναφορά',
    'undo': 'Αναίρεση',
    'redo': 'Επανάληψη',
    'copy': 'Αντιγραφή',
    'paste': 'Επικόλληση',
    'cut': 'Αποκοπή',
    'duplicate': 'Αντίγραφο',
    'move': 'Μετακίνηση',
    'rename': 'Μετονομασία',
    'enable': 'Ενεργοποίηση',
    'disable': 'Απενεργοποίηση',
    'enabled': 'Ενεργοποιημένο',
    'disabled': 'Απενεργοποιημένο',
    'active': 'Ενεργό',
    'inactive': 'Ανενεργό',
    'on': 'Ενεργό',
    'off': 'Ανενεργό',
    'show': 'Εμφάνιση',
    'hide': 'Απόκρυψη',
    'visible': 'Ορατό',
    'hidden': 'Κρυφό',
    'expand': 'Επέκταση',
    'collapse': 'Σύμπτυξη',
    'maximize': 'Μεγιστοποίηση',
    'minimize': 'Ελαχιστοποίηση',
    'fullscreen': 'Πλήρης οθόνη',
    'zoom': 'Μεγέθυνση',
    'fit': 'Προσαρμογή',
    'center': 'Κέντρο',
    'layout': 'Διάταξη',
    'size': 'Μέγεθος',
    'width': 'Πλάτος',
    'height': 'Ύψος',
    'color': 'Χρώμα',
    'theme': 'Θέμα',
    'style': 'Στυλ',
    'format': 'Μορφή',
    'print': 'Εκτύπωση',
    'share': 'Κοινοποίηση',
    'send': 'Αποστολή',
    'receive': 'Λήψη',
    'connect': 'Σύνδεση',
    'disconnect': 'Αποσύνδεση',
    'connected': 'Συνδεδεμένο',
    'disconnected': 'Αποσυνδεδεμένο',
    'online': 'Συνδεδεμένο',
    'offline': 'Εκτός σύνδεσης',
    'sync': 'Συγχρονισμός',
    'login': 'Σύνδεση',
    'logout': 'Αποσύνδεση',
    'sign in': 'Σύνδεση',
    'sign out': 'Αποσύνδεση',
    'register': 'Εγγραφή',
    'password': 'Κωδικός',
    'email': 'Email',
    'username': 'Όνομα χρήστη',
    'account': 'Λογαριασμός',
    'profile': 'Προφίλ',

    # DAPSI(W)R(M) Framework terms
    'drivers': 'Κινητήριες δυνάμεις',
    'driver': 'Κινητήρια δύναμη',
    'activities': 'Δραστηριότητες',
    'activity': 'Δραστηριότητα',
    'pressures': 'Πιέσεις',
    'pressure': 'Πίεση',
    'state': 'Κατάσταση',
    'states': 'Καταστάσεις',
    'state changes': 'Αλλαγές κατάστασης',
    'impacts': 'Επιπτώσεις',
    'impact': 'Επίπτωση',
    'welfare': 'Ευημερία',
    'responses': 'Αποκρίσεις',
    'response': 'Απόκριση',
    'measures': 'Μέτρα',
    'measure': 'Μέτρο',
    'management': 'Διαχείριση',
    'ecosystem': 'Οικοσύστημα',
    'ecosystems': 'Οικοσυστήματα',
    'ecosystem services': 'Υπηρεσίες οικοσυστήματος',
    'marine': 'Θαλάσσιο',
    'marine processes': 'Θαλάσσιες διεργασίες',
    'goods': 'Αγαθά',
    'benefits': 'Οφέλη',
    'goods and benefits': 'Αγαθά και οφέλη',
    'connections': 'Συνδέσεις',
    'connection': 'Σύνδεση',
    'elements': 'Στοιχεία',
    'element': 'Στοιχείο',
    'network': 'Δίκτυο',
    'node': 'Κόμβος',
    'nodes': 'Κόμβοι',
    'edge': 'Ακμή',
    'edges': 'Ακμές',
    'link': 'Σύνδεσμος',
    'links': 'Σύνδεσμοι',
    'graph': 'Γράφημα',
    'diagram': 'Διάγραμμα',
    'causal loop diagram': 'Διάγραμμα αιτιακών βρόχων',
    'cld': 'CLD',
    'feedback': 'Ανατροφοδότηση',
    'feedback loop': 'Βρόχος ανατροφοδότησης',
    'feedback loops': 'Βρόχοι ανατροφοδότησης',
    'reinforcing': 'Ενισχυτικός',
    'balancing': 'Εξισορροπητικός',
    'polarity': 'Πολικότητα',
    'positive': 'Θετικό',
    'negative': 'Αρνητικό',
    'strength': 'Ένταση',
    'confidence': 'Εμπιστοσύνη',
    'uncertainty': 'Αβεβαιότητα',
    'leverage': 'Μόχλευση',
    'leverage point': 'Σημείο μόχλευσης',
    'leverage points': 'Σημεία μόχλευσης',
    'centrality': 'Κεντρικότητα',
    'degree': 'Βαθμός',
    'betweenness': 'Ενδιαμεσότητα',
    'closeness': 'Εγγύτητα',
    'eigenvector': 'Ιδιοδιάνυσμα',
    'pagerank': 'PageRank',
    'metrics': 'Μετρικές',
    'metric': 'Μετρική',
    'indicator': 'Δείκτης',
    'indicators': 'Δείκτες',
    'trend': 'Τάση',
    'trends': 'Τάσεις',

    # Project/PIMS terms
    'stakeholder': 'Ενδιαφερόμενο μέρος',
    'stakeholders': 'Ενδιαφερόμενα μέρη',
    'pims': 'PIMS',
    'project information': 'Πληροφορίες έργου',
    'scenario': 'Σενάριο',
    'scenarios': 'Σενάρια',
    'simulation': 'Προσομοίωση',
    'model': 'Μοντέλο',
    'models': 'Μοντέλα',
    'ses': 'SES',
    'socio-ecological system': 'Κοινωνικο-οικολογικό σύστημα',
    'assessment': 'Αξιολόγηση',
    'evaluation': 'Αξιολόγηση',
    'validation': 'Επικύρωση',
    'workshop': 'Εργαστήριο',
    'interview': 'Συνέντευξη',
    'survey': 'Έρευνα',
    'questionnaire': 'Ερωτηματολόγιο',

    # Analysis terms
    'loop detection': 'Ανίχνευση βρόχων',
    'simplify': 'Απλοποίηση',
    'simplification': 'Απλοποίηση',
    'aggregate': 'Συγκέντρωση',
    'aggregation': 'Συγκέντρωση',
    'cluster': 'Σύμπλεγμα',
    'clustering': 'Ομαδοποίηση',
    'calculate': 'Υπολογισμός',
    'calculation': 'Υπολογισμός',
    'visualize': 'Οπτικοποίηση',
    'visualization': 'Οπτικοποίηση',

    # Regional/Geographic terms
    'regional': 'Περιφερειακό',
    'regional sea': 'Περιφερειακή θάλασσα',
    'mediterranean': 'Μεσόγειος',
    'baltic': 'Βαλτική',
    'north sea': 'Βόρεια Θάλασσα',
    'atlantic': 'Ατλαντικός',
    'caribbean': 'Καραϊβική',
    'coastal': 'Παράκτιο',
    'offshore': 'Υπεράκτιο',

    # User experience levels
    'beginner': 'Αρχάριος',
    'intermediate': 'Μέσος',
    'advanced': 'Προχωρημένος',
    'expert': 'Ειδικός',

    # Time/Duration
    'seconds': 'δευτερόλεπτα',
    'minutes': 'λεπτά',
    'hours': 'ώρες',
    'days': 'ημέρες',
    'weeks': 'εβδομάδες',
    'months': 'μήνες',
    'years': 'έτη',
    'ago': 'πριν',
    'today': 'σήμερα',
    'yesterday': 'χθες',
    'tomorrow': 'αύριο',
    'now': 'τώρα',
    'never': 'ποτέ',
    'always': 'πάντα',

    # Numbers/Quantities
    'first': 'Πρώτο',
    'second': 'Δεύτερο',
    'third': 'Τρίτο',
    'last': 'Τελευταίο',
    'more': 'Περισσότερα',
    'less': 'Λιγότερα',
    'many': 'Πολλά',
    'few': 'Λίγα',
    'some': 'Μερικά',
    'other': 'Άλλο',
    'another': 'Άλλο',

    # Actions/States
    'approved': 'Εγκρίθηκε',
    'rejected': 'Απορρίφθηκε',
    'pending': 'Εκκρεμεί',
    'completed': 'Ολοκληρώθηκε',
    'in progress': 'Σε εξέλιξη',
    'not started': 'Δεν ξεκίνησε',
    'saved': 'Αποθηκεύτηκε',
    'loaded': 'Φορτώθηκε',
    'deleted': 'Διαγράφηκε',
    'added': 'Προστέθηκε',
    'removed': 'Αφαιρέθηκε',
    'changed': 'Άλλαξε',
    'unchanged': 'Αμετάβλητο',

    # Questions/Prompts
    'are you sure': 'Είστε σίγουροι',
    'please confirm': 'Παρακαλώ επιβεβαιώστε',
    'would you like': 'Θα θέλατε',
    'do you want': 'Θέλετε',
    'enter': 'Εισάγετε',
    'type': 'Πληκτρολογήστε',
    'choose': 'Επιλέξτε',
    'specify': 'Καθορίστε',

    # Messages
    'welcome': 'Καλώς ήρθατε',
    'goodbye': 'Αντίο',
    'thank you': 'Ευχαριστώ',
    'please': 'Παρακαλώ',
    'sorry': 'Συγγνώμη',
    'note': 'Σημείωση',
    'important': 'Σημαντικό',
    'tip': 'Συμβουλή',
    'hint': 'Υπόδειξη',
    'example': 'Παράδειγμα',
    'examples': 'Παραδείγματα',
}


def translate_to_greek(english_text):
    """Translate English text to Greek using dictionary lookup."""
    if not english_text:
        return english_text

    # Check for exact match (case-insensitive)
    lower_text = english_text.lower().strip()
    if lower_text in GREEK_TRANSLATIONS:
        greek = GREEK_TRANSLATIONS[lower_text]
        # Preserve original capitalization
        if english_text[0].isupper():
            return greek[0].upper() + greek[1:] if len(greek) > 1 else greek.upper()
        return greek

    # Check if text starts with a known term
    for term, greek in sorted(GREEK_TRANSLATIONS.items(), key=lambda x: -len(x[0])):
        if lower_text.startswith(term + ' '):
            rest = english_text[len(term)+1:]
            translated_rest = translate_to_greek(rest)
            greek_term = greek[0].upper() + greek[1:] if english_text[0].isupper() else greek
            return f"{greek_term} {translated_rest}"

    # For technical terms or unknown text, keep English
    return english_text


def process_translation_file(filepath):
    """Add Greek translations to a translation file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error loading {filepath}: {e}")
        return 0

    added = 0
    translations = data.get('translation', data)

    # Skip if translations is not a dict
    if not isinstance(translations, dict):
        return 0

    for key, value in translations.items():
        if isinstance(value, dict):
            # Check if Greek translation is missing or empty
            if 'el' not in value or not value.get('el') or value.get('el') == '':
                # Get English text to translate
                en_text = value.get('en', '')
                if en_text:
                    greek_text = translate_to_greek(en_text)
                    value['el'] = greek_text
                    added += 1

    # Ensure languages list includes 'el'
    if 'languages' in data and 'el' not in data['languages']:
        data['languages'].append('el')

    # Save updated file
    try:
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"Error saving {filepath}: {e}")
        return 0

    return added


def main():
    """Add Greek translations to all translation files."""
    print("Adding Greek (EL) translations to all files...")
    print("=" * 60)

    total_added = 0
    files_processed = 0

    for root, dirs, files in os.walk('translations'):
        for f in files:
            if f.endswith('.json') and 'backup' not in f.lower():
                filepath = os.path.join(root, f)
                added = process_translation_file(filepath)
                if added > 0:
                    rel_path = os.path.relpath(filepath, 'translations')
                    print(f"  {rel_path}: +{added} Greek translations")
                    total_added += added
                    files_processed += 1

    print("=" * 60)
    print(f"Total Greek translations added: {total_added}")
    print(f"Files updated: {files_processed}")


if __name__ == '__main__':
    main()
