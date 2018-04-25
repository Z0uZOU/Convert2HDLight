# Convert2HDLight
## Script automatique de conversion de médias en format X264 HDLight

> THIS SCRIPT IS ONLY IN FRENCH

> CE SCRIPT EST UNIQUEMENT EN FRANÇAIS

## **IMPORTANT:**

[<img src="https://github.com/Z0uZOU/Convert2HDLight/blob/master/.cache-icons/extensions-gnome.png">](https://extensions.gnome.org/extension/1176/argos/) 
[<img src="https://github.com/Z0uZOU/Convert2HDLight/blob/master/.cache-icons/pushover.png">](https://pushover.net/)

+ Ce script peut exploiter Argos, vous devez imperativement l'avoir installé préalablement.
  - Page officielle de l'extension à installer: https://extensions.gnome.org/extension/1176/argos/
  - GitHub officiel de Argos: https://github.com/p-e-w/argos
+ Les notifications push de ce scripts utilisent le système PushOver
  - Page officielle de PushOver: https://pushover.net/
  - Lien vers la boutique Android: https://play.google.com/store/apps/details?id=net.superblock.pushover
  - Lien vers la boutique Apple: https://itunes.apple.com/us/app/pushover-notifications/id506088175

## **Pourquoi ce script:**

Le HDLight en X264 est un format fabuleux, la perte de qualité par rapport à la version HDRip est minime et le gain de place est vraiment intéressant. Un fichier, un film par exemple, qui faisait de 8 à 12Go se retrouve à une taille de 2 à 4Go.

De plus la quasi totalité des lecteurs du marché est capable de le lire nativement, donc niveau compatibilité c'est parfait.

L'idée de base est donc d'encoder automatiquement les médias dans ce format.

## **À savoir avant de commencer:**
- Ce script nécessite d'être executé depuis le compte root
- Ce script "devrait" installer les dépendances nécessaires à son exécution
- Ce script va modifier le cron pour automatiser les conversions (toute les x minutes)


## **Remerciements :**

Notre script se base sur de nombreux outils développés par la communauté, voici les principaux:
- FileBot
- HandBrake
- Argos
