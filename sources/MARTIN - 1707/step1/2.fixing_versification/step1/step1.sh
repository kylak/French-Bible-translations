#!/bin/sh
# ===============================================================================
# Script pour corriger la versification de MARTIN.txt
# 
# REGLE : Un marqueur (X:Y) n'est traité QUE si :
#         - X > chapitre_actuel, OU
#         - X == chapitre_actuel ET Y > verset_actuel
#
# Utilisation : ./step1.sh <fichier_source> > sortie.txt
# ===============================================================================

[ -z "$1" ] || [ ! -f "$1" ] && { echo "Usage: $0 <fichier>" >&2; exit 1; }

TMP=$(mktemp)
trap "rm -f $TMP" EXIT

# Étape 1 : Créer le script AWK pour traiter les marqueurs
cat > $TMP << 'AWKEND'
{
    # Ignorer les lignes vides
    if (NF == 0) { print ""; next }
    
    # Extraire l'ID de la ligne
    line = $0
    id = substr(line, 1, 8)
    if (id !~ /^[0-9]{8}$/) { print line; next }
    
    # Extraire le texte (après l'ID et les espaces)
    text = substr(line, 9)
    gsub(/^[ \t]+/, "", text)
    
    # Extraire livre, chapitre et verset actuels
    livre = substr(id, 1, 2)
    chapitre_actuel = int(substr(id, 3, 3))
    verset_actuel = int(substr(id, 6, 3))
    
    # Initialisation
    pos = 1
    first_segment = 1
    current_id = id
    current_text = text
    
    # Chercher tous les marqueurs valides dans la ligne
    while (pos <= length(current_text)) {
        # Trouver la prochaine parenthèse ouvrante
        open_paren_pos = index(substr(current_text, pos), "(")
        if (open_paren_pos == 0) break
        pos_in_text = pos + open_paren_pos - 1
        
        # Trouver la parenthèse fermante
        close_paren_pos = index(substr(current_text, pos_in_text), ")")
        if (close_paren_pos == 0) {
            pos = pos_in_text + 1
            continue
        }
        end_pos_in_text = pos_in_text + close_paren_pos - 1
        
        # Extraire le contenu du marqueur
        marker_content = substr(current_text, pos_in_text + 1, end_pos_in_text - pos_in_text - 1)
        
        # Vérifier si c'est un marqueur valide (N:N)
        if (marker_content ~ /^[0-9]+:[0-9]+$/) {
            split(marker_content, parts, ":")
            marker_chapter = int(parts[1])
            marker_verse = int(parts[2])
            
            # Vérifier si le marqueur est APRES le verset actuel
            if (marker_chapter > chapitre_actuel || 
                (marker_chapter == chapitre_actuel && marker_verse > verset_actuel)) {
                
                # Extraire texte avant et après le marqueur
                text_before = substr(current_text, 1, pos_in_text - 1)
                text_after = substr(current_text, pos_in_text)
                
                # Générer le nouvel ID
                new_id = sprintf("%s%03d%03d", livre, marker_chapter, marker_verse)
                
                # Sortir le segment avant le marqueur avec l'ID courant
                if (length(text_before) > 0) {
                    # Nettoyer l'espace en fin de text_before
                    sub(/[ \t]+$/, "", text_before)
                    printf "%s %s\n", current_id, text_before
                }
                first_segment = 0

                # Chaque verset MARTIN est sur sa propre ligne ; on ne fusionne pas
                # avec la ligne suivante. On continue simplement à scanner le texte
                # restant (qui pourrait contenir d'autres marqueurs).
                current_id = new_id
                current_text = text_after
                pos = 1
                chapitre_actuel = marker_chapter
                verset_actuel = marker_verse
                
            } else {
                # Marqueur non valide, continuer la recherche
                pos = end_pos_in_text + 1
            }
        } else {
            pos = end_pos_in_text + 1
        }
    }
    
    # Sortir le dernier segment
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
AWKEND

# Étape 2 : Appliquer AWK et nettoyer les lignes vides
# Étape 3 : Concaténer les lignes avec le même ID consécutif
awk -f $TMP "$1" | sed '/^[0-9]\{8\}$/d' | \
awk '
{
    if (NF == 0) {
        if (length(saved_line) > 0) print saved_line
        saved_line = ""
        prev_id = ""
        print ""
        next
    }
    current_id = substr($0, 1, 8)
    current_rest = substr($0, 9)
    gsub(/^[ \t]+/, "", current_rest)
    if (current_id == prev_id) {
        # Accumuler dans saved_line au lieu d''imprimer tout de suite,
        # pour éviter le doublon (l''ancien saved_line non-fusionné
        # serait sinon imprimé à la transition suivante ou en END).
        saved_line = saved_line " " current_rest
    } else {
        if (length(saved_line) > 0) print saved_line
        saved_line = $0
        prev_id = current_id
    }
}
END { if (length(saved_line) > 0) print saved_line }
'
