#!/usr/bin/env bash

# Script pour télécharger et comparer la Bible Darby

URL="https://www.bibliquest.net/Bible/BibleJNDhtm-Bible.htm"
DOWNLOADED_FILE="BibleJNDhtm-Bible.htm"
LOCAL_FILE="Darby.htm"

echo "Téléchargement de $URL..."
curl -L -o "$DOWNLOADED_FILE" "$URL"

if [ $? -ne 0 ]; then
    echo "Erreur lors du téléchargement"
    exit 1
fi

echo "Téléchargement terminé"
echo ""

if [ ! -f "$LOCAL_FILE" ]; then
    echo "Erreur: Le fichier local $LOCAL_FILE n'existe pas"
    exit 1
fi

echo "Comparaison des fichiers..."
echo "----------------------------------------"

# Vérifier si les fichiers sont identiques
if cmp -s "$DOWNLOADED_FILE" "$LOCAL_FILE"; then
    echo "✓ Les fichiers sont identiques"
else
    echo "✗ Les fichiers sont différents"
    echo ""
    echo "Différences détaillées (100 premières lignes de diff):"
    diff -u "$LOCAL_FILE" "$DOWNLOADED_FILE" | head -100
    echo ""
    echo "Statistiques:"
    echo "  Taille du fichier téléchargé: $(wc -c < "$DOWNLOADED_FILE") octets"
    echo "  Taille du fichier local:      $(wc -c < "$LOCAL_FILE") octets"
fi

# On déplace le fichier telecharge dans /tmp 
echo ""
mv "$DOWNLOADED_FILE" /tmp
echo "Le fichier téléchargé '$DOWNLOADED_FILE' se trouve dans /tmp."
