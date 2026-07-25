# 🌿 Gallaecia Dots

### Arch + Hyprland. En galego. Instalación mínima. Base actualizable.

Gallaecia Dots é un conxunto de dotfiles e un instalador interactivo para montar rapidamente un escritorio baseado en **Arch Linux + Hyprland**, cunha identidade galega e unha base moi concreta: **o mínimo imprescindible para arrancar ben, con Noctalia e os paquetes esenciais xa listos**.

Non pretende ser unha distribución nin unha capa pesada sobre o sistema. O obxectivo é ofrecer un punto de partida pequeno, actualizable e fácil de manter.

## 🐚 Que é Gallaecia Dots?

**Gallaecia Dots** combina:

- Un instalador que prepara o sistema paso a paso
- Configuración base para Hyprland, Noctalia, greetd, GTK, Qt e portais XDG entre outros
- Unha selección mínima de paquetes fundamentais
- Opcións para escoller só as aplicacións que de verdade queres instalar

A idea é sinxela:

**Instalación curta, base sólida e liberdade para personalizar despois.**

## 🧱 Enfoque minimalista e opinionated

Este proxecto xa non está pensado como un “pack completo” de aplicacións para todo o mundo.

A visión actual é máis pequena e máis clara:

- Instalar só o esencial para que o escritorio funcione
- Incluír **Noctalia** como peza central da experiencia
- Manter configuracións que teñen sentido como base común
- Deixar o resto como elección do usuario

Por defecto, o instalador non che enche o sistema de apps por categorías enormes. Primeiro instala o núcleo, e despois pregúntache polas ferramentas que queres realmente.

## 🌿 Feito en galego

Gallaecia Dots está pensado arredor do galego.

O instalador, as configuracións propias e o escritorio utilizan o galego como idioma principal.

Durante a instalación, o sistema configúrase co seguinte orde de idiomas:

```text
Galego → Español → Inglés
```

Deste xeito, cando unha aplicación non dispoña de tradución ao galego, o sistema tentará usar primeiro o español e despois o inglés.

Tamén inclúe fondos de pantalla inspirados en Galicia e na súa identidade.

## 📦 Que instala?

A instalación divídese en dúas partes:

### Núcleo obrigatorio

Isto é o que o proxecto considera imprescindible para a base:

- Hyprland
- Noctalia
- Noctalia Greeter
- greetd
- XDG Desktop Portals
- PipeWire
- Kitty
- Flatpak
- yay
- Configuración GTK e Qt
- XDG User Directories
- Tipografías e iconas básicas
- Dependencias comúns do escritorio

### Aplicacións opcionais

Despois da base, o instalador pregúntache por categorías de aplicacións para que só instales o que che interesa.

As categorías actuais son:

- Terminal
- Editor de terminal
- IDE ou editor gráfico
- Navegador
- Explorador de arquivos
- Audio
- Vídeo
- PDF
- Imaxes
- Correo
- Chat
- Creatividade
- Oficina e notas
- Xogos e tendas
- Utilidades
- Desenvolvemento, incluídos Docker + Compose e Git
- Rede e privacidade
- Descargas e personalización

Moitas categorías permiten escoller varias opcións, e nalgúns casos tamén definir unha app por defecto.

## 🐚 Helpers interactivos

As aplicacións opcionais poden instalar funcións Bash guiadas con `gum` para
as tarefas máis habituais. Cada comando dispón de axuda propia con `--help` e
permite reenviar opcións ao programa orixinal despois de `--`:

```bash
docker-logs --follow -- --timestamps
git-log -- --since="1 week ago"
yt-dlp-video -- --cookies-from-browser firefox
```

Os prompts, menús, filtros e inputs sepáranse sempre do texto ou da saída
anterior cunha liña baleira, sen modificar os valores devoltos polos comandos.

### Git e GitHub

Os helpers de Git permiten:

- Configurar a autoría con `git-credenciales` e iniciar sesión con
  `github-login`.
- Preparar e gardar cambios con `git-add`, `git-commit` e `git-save`.
- Consultar cambios e historial con `git-diff`, `git-log` e
  `git-commit-show`.
- Descargar e publicar cambios con `git-pull` e `git-push`.
- Cambiar, crear, borrar e integrar ramas con `git-branch-switch`,
  `git-branch-new`, `git-branch-delete` e `git-branch-merge`.
- Gardar e recuperar traballo temporal con `git-stash-save` e
  `git-stash-pop`.

### Docker, Compose e Buildx

Os helpers de Docker cobren:

- Listaxe, shell, consola e logs con `docker-ps`, `docker-shell`,
  `docker-attach` e `docker-logs`.
- Inicio, parada, reinicio e borrado con `docker-container-start`,
  `docker-container-stop`, `docker-container-restart` e
  `docker-container-delete`.
- Listaxe, etiquetado e borrado de imaxes con `docker-images`,
  `docker-tag` e `docker-image-delete`.
- Listaxe e borrado de redes e volumes con `docker-networks`,
  `docker-network-delete`, `docker-volumes` e `docker-volume-delete`.
- Estado, inicio, parada, logs, reconstrución e actualización de Compose con
  `compose-ps`, `compose-up`, `compose-down`, `compose-logs`,
  `compose-rebuild` e `compose-update`.
- Builds locais e limpeza guiada con `docker-build` e `docker-clean`.
- Acceso a Docker Hub ou outros rexistros con `docker-login`,
  `docker-logout`, `docker-search`, `docker-pull` e `docker-push`.

As operacións de borrado sempre piden confirmación. As accións forzadas ou que
poden eliminar datos importantes, como volumes, requiren unha segunda
confirmación.

Ao instalar Docker tamén se activa `docker.service` e engádese o usuario ao
grupo `docker`. O acceso sen `sudo` queda dispoñible despois de reiniciar.

### Descargas e helpers reutilizables

`yt-dlp-video`, `yt-dlp-musica` e `spotdl-musica` admiten `--once`, `--url` e
opcións adicionais para o programa orixinal despois de `--`.

Os helpers públicos de interface, comandos e ficheiros tamén ofrecen
`--help`. As operacións de ficheiros permiten revisar o resultado con
`--dry-run`.

Os comandos propios do usuario poden gardarse en
`~/.config/bashrc/NNN-nome`. Estes ficheiros están pensados para
personalización e non deben ser substituídos polas actualizacións habituais.

## 🚀 Instalación

> [!WARNING]
> O instalador modifica e substitúe diferentes ficheiros de configuración do sistema e do usuario.
>
> Recoméndase utilizar Gallaecia Dots sobre unha instalación limpa de Arch Linux, sen entorno gráfico previo.

Executa:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/XurxoMF/gallaecia-dots/release/install.sh)
```

O instalador guiarate paso a paso cunha interface interactiva.

> [!IMPORTANT]
> Se tras reiniciar o sistema ao rematar a instalación che aparece un erro de Hyprland ou algunha app non funciona correctamente reinicia de novo ou cambia o fondo de pantalla seleccionando o mesmo ou un novo para que Noctalia xere as paletas de cores correctamente.

## 🧰 Instalación con archinstall

Se prefires facer a instalación base con `archinstall`, primeiro inicia o sistema co USB de Arch Linux e abre unha consola. Desde aí baixa o perfil JSON do proxecto:

```bash
curl -fsSL -o user_configuration.json https://raw.githubusercontent.com/XurxoMF/gallaecia-dots/release/archinstall/user_configuration.json
```

Despois lanza `archinstall` cargando ese ficheiro:

```bash
archinstall --config user_configuration.json
```

Se a túa versión de `archinstall` emprega outro modo para cargar perfís, escolle a opción de importar configuración e usa ese mesmo ficheiro `user_configuration.json`.

Durante o asistente, só tes que completar o que queda pendente:

1. Crear o usuario normal.
2. Poñer o contrasinal de `root`.
3. Escoller o particionamento dos discos.

O resto da configuración xa vén preparada no JSON.

Cando remate a instalación base, reinicia, entra no sistema co teu usuario e xa poderás seguir coa parte de Gallaecia Dots se a precisas para deixar o escritorio listo.

## 🔄 Actualizacións e mantemento

Unha parte importante desta visión é que os dotfiles base son **actualizables**.

Isto significa:

- A base común pode evolucionar con novas versións
- Os ficheiros controlados polo proxecto poden recibir melloras
- As instalacións novas e as existentes poden seguir a evolución do proxecto

Ao mesmo tempo, Gallaecia Dots segue sendo unha base pequena e clara:

- Podes editar libremente a túa configuración
- Podes borrar o que non uses
- Podes engadir as túas propias pezas
- O proxecto non pretende ocultarche como está montado o sistema

## ⚠️ Estado do proxecto

Gallaecia Dots é un proxecto persoal en desenvolvemento.

Pode haber cambios importantes entre versións e algunhas actualizacións de Arch Linux, Hyprland ou outros compoñentes poden requirir axustes manuais na configuración.

Se algo rompe:

**Benvido a Arch.** 🫡

## 🤝 Contribucións

As propostas, correccións e melloras son benvidas.

Podes abrir unha issue ou enviar unha pull request a través de GitHub.

## 📜 Licenza

Baixo a licenza MIT calquera poderá facer o que queira con este contido. Agradeceríalle que, se fas un fork ou algo similar, menciones a autoría orixinal.
