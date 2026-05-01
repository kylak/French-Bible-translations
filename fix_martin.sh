#!/bin/bash
# ===============================================================================
# Script pour corriger la versification d'un fichier Bible au format MARTIN
# 
# Utilisation : ./fix_martin.sh <fichier_source>
# 
# Le script lit le fichier source et écrit le résultat corrigé sur stdout.
# 
# REGLE : Un marqueur (X:Y) n'est traité QUE si :
#         - X > chapitre_actuel, OU
#         - X == chapitre_actuel ET Y > verset_actuel
#
# Exemple :
#   ./fix_martin.sh complete-Bible/MARTIN.txt > complete-Bible/MARTIN_bonne_versification.txt
# ===============================================================================

# Vérifier qu'un fichier source est fourni
if [ -z "$1" ]; then
    echo "Usage: $0 <fichier_source>" >&2
    echo "Exemple: $0 complete-Bible/MARTIN.txt > MARTIN_bonne_versification.txt" >&2
    exit 1
fi

INPUT="$1"

# Vérifier que le fichier existe
if [ ! -f "$INPUT" ]; then
    echo "Erreur: Le fichier '$INPUT' n'existe pas." >&2
    exit 1
fi

echo "Traitement de $INPUT..." >&2

# Créer un fichier temporaire pour le script AWK
AWK_SCRIPT=$(mktemp)
trap "rm -f $AWK_SCRIPT" EXIT

cat > "$AWK_SCRIPT" << 'ENDOFSCRIPT'
{
    if (length($0) == 0) {
        print ""
        next
    }
    
    line = $0
    id = substr(line, 1, 8)
    if (id !~ /^[0-9]{8}$/) {
        print line
        next
    }
    
    rest = substr(line, 9)
    text_start = 1
    while (substr(rest, text_start, 1) ~ /[ \t]/) {
        text_start++
    }
    text = substr(rest, text_start)
    
    livre = substr(id, 1, 2)
    chapitre_actuel = int(substr(id, 3, 3))
    verset_actuel = int(substr(id, 6, 3))
    
    pos = 1
    first_segment = 1
    current_id = id
    current_text = text
    
    while (pos <= length(current_text)) {
        open_paren_pos = index(substr(current_text, pos), "(")
        if (open_paren_pos == 0) break
        pos_in_text = pos + open_paren_pos - 1
        
        close_paren_pos = index(substr(current_text, pos_in_text), ")")
        if (close_paren_pos == 0) {
            pos = pos_in_text + 1
            continue
        }
        end_pos_in_text = pos_in_text + close_paren_pos - 1
        
        marker_content = substr(current_text, pos_in_text + 1, end_pos_in_text - pos_in_text - 1)
        
        if (marker_content ~ /^[0-9]+:[0-9]+$/) {
            split(marker_content, parts, ":")
            marker_chapter = int(parts[1])
            marker_verse = int(parts[2])
            
            if (marker_chapter > chapitre_actuel || 
                (marker_chapter == chapitre_actuel && marker_verse > verset_actuel)) {
                
                text_before = substr(current_text, 1, pos_in_text - 1)
                text_after = substr(current_text, pos_in_text, length(current_text) - pos_in_text + 1)
                
                new_id = sprintf("%s%03d%03d", livre, marker_chapter, marker_verse)
                
                if (first_segment) {
                    if (length(text_before) > 0) {
                        printf "%s %s\n", current_id, text_before
                    }
                    first_segment = 0
                } else {
                    if (length(text_before) > 0) {
                        printf "%s %s\n", current_id, text_before
                    }
                }
                
                current_id = new_id
                current_text = text_after
                pos = 1
                chapitre_actuel = marker_chapter
                verset_actuel = marker_verse
                
            } else {
                pos = end_pos_in_text + 1
            }
        } else {
            pos = end_pos_in_text + 1
        }
    }
    
    if (!first_segment) {
        if (length(current_text) > 0) {
            printf "%s %s\n", current_id, current_text
        } else {
            printf "%s\n", current_id
        }
    } else {
        print line
    }
}
ENDOFSCRIPT

# Exécuter AWK avec le script temporaire, puis nettoyer les lignes vides
/run/current-system/sw/bin/awk -f "$AWK_SCRIPT" "$INPUT" | sed '/^[0-9]\{8\}$/d'

echo "Traitement terminé." >&2
