# eve-telnets

Ouvrir dans le terminal la console des nœuds démarrés d'un lab [EVE-NG](https://www.eve-ng.net/), sans chercher les ports.

```text
$ eve-telnets
  R-BREST          192.168.1.61:32769
  R-PARIS          192.168.1.61:32770
> R-STRASBOURG     192.168.1.61:32771
  SW-BREST         192.168.1.61:32772
  …
── R-STRASBOURG · Ctrl+D pour quitter ──
R-STRASBOURG>
```

- **La liste suit le lab** : elle est relue à chaque lancement. Un nœud démarré apparaît, un nœud arrêté disparaît, rien à configurer.
- **Ctrl+D quitte la console** et ramène à la liste. Pas besoin de `Ctrl+]` puis `quit`, qui ne marche pas sur un clavier AZERTY.
- **Les liens « console native » d'EVE-NG** (`telnet://…`, un clic sur un nœud dans le navigateur) peuvent s'ouvrir avec eve-telnets.

*English: a terminal picker for the consoles of the running nodes of an EVE-NG lab. The node list is read live over SSH; Ctrl+D closes a console.*

## Comment ça marche

Sur la VM EVE-NG, chaque nœud démarré tourne dans un processus `…_wrapper` lancé avec `-T <pod> -D <n° du nœud> -t <nom>`. Sa console telnet écoute sur le port `32768 + 128 × pod + n°`. eve-telnets lit ces processus en SSH (`ps`), et en tire le nom et le port de chaque nœud.

Pourquoi pas l'API web d'EVE-NG : dans la version Community, une connexion par l'API remplace la session du navigateur, qui se retrouve déconnecté.

La console passe par `socat` (terminal brut, `Ctrl+D` ferme la connexion) et `ncat --telnet` (négociation telnet), et pas par le client `telnet`.

## Prérequis

- Linux (sous Windows : WSL).
- Un accès **root en SSH par clé** à la VM EVE-NG : c'est le cas si c'est **ta** VM (VMware, Proxmox…). Sur un serveur EVE-NG partagé où tu n'es pas root, ça ne marchera pas.
- `ssh`, `socat`, `ncat`, et `sshs` ou `fzf` pour la liste.

Testé avec EVE-NG Community 5 et des nœuds IOL ; les nœuds QEMU (vIOS…) utilisent le même mécanisme.

## Installation

```bash
# Dépendances
sudo pacman -S socat nmap fzf          # Arch (ncat est dans nmap)
sudo apt install socat ncat fzf        # Debian / Ubuntu / WSL
sudo dnf install socat nmap-ncat fzf   # Fedora

git clone https://github.com/Arnaudmyges/eve-telnets.git
cd eve-telnets
./install.sh                 # copie eve-telnets dans ~/.local/bin
./install.sh --url-handler   # en plus : les liens telnet:// du navigateur s'ouvrent avec eve-telnets
```

Puis donner ta clé SSH à la VM EVE-NG (mot de passe root demandé une fois, `eve` par défaut) :

```bash
cat >> ~/.ssh/config << 'EOF'

Host eve-ng
  HostName 192.168.1.61   # l'IP de ta VM EVE-NG
  User root
EOF
ssh-copy-id eve-ng
```

Si ta VM s'appelle autrement : `eve-telnets -H mon-alias`, la variable `EVE_TELNETS_HOST`, ou une ligne dans `~/.config/eve-telnets/host`.

Désinstaller : `./install.sh --uninstall`.

### Le navigateur demande « Ouvrir avec… » à chaque clic

Une autre application déclare aussi les liens `telnet://` (souvent KTelnetService, installé avec les bibliothèques KDE), et le portail du bureau demande laquelle utiliser. Pour lui retirer seulement `telnet://`, avec une copie locale qui prend le pas sur celle du système :

```bash
grep -l x-scheme-handler/telnet /usr/share/applications/*.desktop   # qui d'autre ?
A=~/.local/share/applications
sed 's|x-scheme-handler/telnet;||' /usr/share/applications/ktelnetservice6.desktop > $A/ktelnetservice6.desktop
update-desktop-database $A
```

Si la fenêtre revient encore : `systemctl --user restart xdg-desktop-portal`.

## Utilisation

| Commande | Effet |
| --- | --- |
| `eve-telnets` | liste des nœuds démarrés, Entrée pour la console |
| `eve-telnets -s brest` | liste déjà filtrée |
| `eve-telnets -l` | nom et port de chaque nœud, pour un script |
| `eve-telnets --console 192.168.1.61 32769` | une console sans la liste |
| `eve-telnets telnet://192.168.1.61:32769` | idem, comme un lien EVE-NG |

Dans une console, **Ctrl+D** pour quitter. Ctrl+D ne parvient donc plus à l'équipement : sur Cisco IOS, il efface le caractère sous le curseur, comme `Suppr`.

La liste utilise [sshs](https://github.com/quantumsheep/sshs) s'il est installé, sinon [fzf](https://github.com/junegunn/fzf). Pour forcer fzf : `EVE_TELNETS_PICKER=fzf`.

## Projets proches

- [eve-ng-integration](https://github.com/SmartFinn/eve-ng-integration) : l'équivalent Linux du « Client Side Pack » Windows d'EVE-NG (liens telnet, capture Wireshark, VNC, RDP depuis le navigateur).
- [evengsdk](https://github.com/ttafsir/evengsdk) : SDK Python et CLI pour l'API REST d'EVE-NG (labs, nœuds, configurations).

## Licence

MIT
