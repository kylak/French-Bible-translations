#!/usr/bin/gawk -f
# AWK script to format Martin 1707 Bible translation from HTML to bbcccvvv format
# Usage: gawk -f format_martin.awk sources/MARTIN/source.html > MARTIN_1707.txt

BEGIN {
    # Book mappings for French Martin translation (Protestant order)
    # Old Testament (01-39)
    BOOK["Gn"] = 1; BOOK["Gen"] = 1; BOOK["Ge"] = 1
    BOOK["Ex"] = 2; BOOK["Exo"] = 2
    BOOK["Lv"] = 3; BOOK["Lev"] = 3
    BOOK["Nm"] = 4; BOOK["Nb"] = 4; BOOK["Num"] = 4
    BOOK["Dt"] = 5; BOOK["Deu"] = 5
    BOOK["Js"] = 6; BOOK["Jos"] = 6
    BOOK["Jg"] = 7; BOOK["Jdg"] = 7
    BOOK["Rt"] = 8; BOOK["Rut"] = 8
    BOOK["1S"] = 9; BOOK["1Sa"] = 9; BOOK["1 S"] = 9
    BOOK["2S"] = 10; BOOK["2Sa"] = 10; BOOK["2 S"] = 10
    BOOK["1R"] = 11; BOOK["1Ki"] = 11; BOOK["1 R"] = 11
    BOOK["2R"] = 12; BOOK["2Ki"] = 12; BOOK["2 R"] = 12
    BOOK["1Ch"] = 13; BOOK["1Chr"] = 13
    BOOK["2Ch"] = 14; BOOK["2Chr"] = 14
    BOOK["Esd"] = 15; BOOK["Ezr"] = 15
    BOOK["Ne"] = 16; BOOK["Neh"] = 16
    BOOK["Est"] = 17; BOOK["Esth"] = 17
    BOOK["Jb"] = 18; BOOK["Job"] = 18
    BOOK["Ps"] = 19; BOOK["Psa"] = 19
    BOOK["Pr"] = 20; BOOK["Pro"] = 20; BOOK["Prov"] = 20
    BOOK["Ec"] = 21; BOOK["Ecc"] = 21; BOOK["Qo"] = 21
    BOOK["Ct"] = 22; BOOK["Sng"] = 22; BOOK["Cant"] = 22
    BOOK["Es"] = 23; BOOK["Isa"] = 23; BOOK["Esaïe"] = 23; BOOK["Ésaïe"] = 23; BOOK["Isaïe"] = 23
    BOOK["Jr"] = 24; BOOK["Jer"] = 24
    BOOK["La"] = 25; BOOK["Lam"] = 25
    BOOK["Ez"] = 26; BOOK["Eze"] = 26; BOOK["Ezk"] = 26
    BOOK["Dn"] = 27; BOOK["Dan"] = 27; BOOK["Da"] = 27
    
    # Minor Prophets
    BOOK["Os"] = 28; BOOK["Hos"] = 28
    BOOK["Jl"] = 29; BOOK["Joe"] = 29
    BOOK["Am"] = 30; BOOK["Amo"] = 30
    BOOK["Ab"] = 31; BOOK["Oba"] = 31; BOOK["Abd"] = 31
    BOOK["Jon"] = 32; BOOK["Jnh"] = 32
    BOOK["Mi"] = 33; BOOK["Mic"] = 33
    BOOK["Na"] = 34; BOOK["Nah"] = 34
    BOOK["Ha"] = 35; BOOK["Hab"] = 35
    BOOK["So"] = 36; BOOK["Zep"] = 36; BOOK["Soph"] = 36
    BOOK["Ag"] = 37; BOOK["Hag"] = 37
    BOOK["Za"] = 38; BOOK["Zec"] = 38; BOOK["Zach"] = 38
    BOOK["Ma"] = 39; BOOK["Mal"] = 39
    
    # New Testament (40-66)
    BOOK["Mt"] = 40; BOOK["Mat"] = 40; BOOK["Matt"] = 40
    BOOK["Mc"] = 41; BOOK["Mar"] = 41; BOOK["Mrk"] = 41; BOOK["Mk"] = 41
    BOOK["Lc"] = 42; BOOK["Luk"] = 42; BOOK["Lk"] = 42
    BOOK["Jn"] = 43; BOOK["Joh"] = 43
    BOOK["Ac"] = 44; BOOK["Act"] = 44
    BOOK["Rm"] = 45; BOOK["Rom"] = 45
    BOOK["1Co"] = 46; BOOK["1Cor"] = 46
    BOOK["2Co"] = 47; BOOK["2Cor"] = 47
    BOOK["Gal"] = 48; BOOK["Ga"] = 48
    BOOK["Eph"] = 49; BOOK["Ep"] = 49
    BOOK["Ph"] = 50; BOOK["Php"] = 50; BOOK["Phi"] = 50
    BOOK["Col"] = 51
    BOOK["1Th"] = 52; BOOK["1Thess"] = 52
    BOOK["2Th"] = 53; BOOK["2Thess"] = 53
    BOOK["1Ti"] = 54; BOOK["1Tim"] = 54
    BOOK["2Ti"] = 55; BOOK["2Tim"] = 55
    BOOK["Tt"] = 56; BOOK["Tit"] = 56
    BOOK["Phm"] = 57; BOOK["Phlm"] = 57
    BOOK["Hé"] = 58; BOOK["He"] = 58; BOOK["Heb"] = 58; BOOK["Hébreux"] = 58; BOOK["Hebreux"] = 58
    BOOK["Jc"] = 59; BOOK["Jas"] = 59; BOOK["Ja"] = 59
    BOOK["1P"] = 60; BOOK["1Pe"] = 60; BOOK["1Pet"] = 60
    BOOK["2P"] = 61; BOOK["2Pe"] = 61; BOOK["2Pet"] = 61
    BOOK["1Jn"] = 62; BOOK["1Jo"] = 62
    BOOK["2Jn"] = 63; BOOK["2Jo"] = 63
    BOOK["3Jn"] = 64; BOOK["3Jo"] = 64
    BOOK["Jd"] = 65; BOOK["Jude"] = 65
    BOOK["Ap"] = 66; BOOK["Rev"] = 66; BOOK["Re"] = 66
}

# Process each line
{
    # PIÈGE 1 ÉVITÉ: Le fichier source contient plusieurs classes de paragraphes
    # (paragraph-Standard, paragraph-P6, paragraph-P8, paragraph-P9, etc.), exemple:
    # <p class="paragraph-Standard">Gn 10:26 Et Joktan engendra Almodad, Séleph, Hatsarmaveth, et Jérah,</p>
    # <p class="paragraph-P8">Gn 10:27 Hadoram, Uzal, Dikla,</p>
    # Solution: On ne filtre PAS par classe spécifique, on capture TOUTES les balises <p>
    #
    # PIÈGE 2 ÉVITÉ: Certains versets contiennent des balises à l'intérieur
    # Exemple 1: <p class="paragraph-Standard"><a id="OLE_LINK29"/>Gn 50:26 texte</p>
    # Exemple 2: <p class="paragraph-Standard"><span class="text-T4">Js 15:23 texte</span></p>
    # Solution: D'abord nettoyer TOUTES les balises HTML, puis extraire.
    line = $0
    clean_line = line
    gsub(/<[^>]+>/, "", clean_line)
    
    # PIÈGE 3 ÉVITÉ: Les abréviations accentuées (Hé, Ésaïe, Esdras) ne sont PAS
    # capturées par le pattern [A-Za-z0-9]+ (qui n'inclut pas é, è, ç, etc.)
    # Exemple: <p class="paragraph-Standard">Hé 1:1 Dieu ayant anciennement...</p>
    # Solution: pattern étendu avec les caractères accentués franquais.
    if (match(clean_line, /([A-Za-z0-9éèçàûîôÿœëäïöüËÄÏÖÜ]+) ([0-9]+):([0-9]+) (.+)/, arr)) {
        abbrev = arr[1]
        chapter = arr[2]
        verse = arr[3]
        text = arr[4]
        
        # Clean HTML entities from text
        gsub(/&amp;/, "&", text)
        gsub(/&lt;/, "<", text)
        gsub(/&gt;/, ">", text)
        gsub(/&quot;/, "\"", text)
        gsub(/&apos;/, "'", text)
        gsub(/&nbsp;/, " ", text)
        gsub(/&[a-z]+;/, "", text)
        
        # PIÈGE 4 ÉVITÉ: Espaces multiples créés par suppression des balises internes
        # Une suppression de balise au sein du texte crée un espace :
        # Exemple 1: "<span class='text-T5'>Js 15:26 Amam,</span><a id='OLE_LINK71'/><span class='text-T5'> Sémah</span>"
        #          → Après nettoyage balises: "Js 15:26 Amam,  Sémah" (deux espaces consécutifs)
        #          → Après gsub(/[ \t]+/, " ", text): "Js 15:26 Amam, Sémah"
        # Exemple 2: "<span class='text-T3'>Ps 25:5 [He. Vau.] </span>Adresse-moi..."
        #          → Après nettoyage balises: "Ps 25:5 [He. Vau.]  Adresse-moi..." (deux espaces consécutifs)
        #          → Après gsub: "Ps 25:5 [He. Vau.] Adresse-moi..."
        # Les gsub début/fin sont une précaution (pas de cas trouvé dans le fichier source).
        gsub(/^[ \t]+/, "", text)
        gsub(/[ \t]+$/, "", text)
        gsub(/[ \t]+/, " ", text)
        
        # Validation: vérifier que l'abréviation existe et que le texte n'est pas vide
        if (abbrev in BOOK && text != "" && text != ".") {
            book_num = BOOK[abbrev]
            # Format final: bbcccvvv (8 chiffres) + espace + texte
            ref = sprintf("%02d%03d%03d", book_num, chapter+0, verse+0)
            print ref " " text
        }
    }
}
