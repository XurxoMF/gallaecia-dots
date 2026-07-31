# Guía para axentes

## Obxectivo do proxecto

Gallaecia Dots é un conxunto de dotfiles e un instalador interactivo para preparar un escritorio minimalista baseado en Arch Linux, Hyprland e Noctalia. O proxecto ofrece unha base pequena, actualizable e en galego, e permite que cada usuario escolla as aplicacións que quere instalar.

Non é unha distribución nin pretende abstraer o funcionamento de Arch. Os scripts empregan directamente ferramentas como `pacman`, `yay`, `flatpak`, `pipx`, `nmcli`, `systemctl` e `rustup`.

Emprega o galego nos comentarios, mensaxes da interface, documentación e nomes propios novos. Mantén os nomes técnicos, comandos e identificadores na forma que corresponda ao programa ou API utilizada.

## Estrutura do repositorio

- `README.md`: descrición pública, instalación e filosofía do proxecto.
- `install.sh`: bootstrap e punto de entrada. Instala os prerequisitos, clona o repo en `~/.dotfiles`, decide o modo de instalación e delega na base ou nas actualizacións.
- `updates/base.sh`: instalación inicial completa. Debe representar sempre o estado máis recente do proxecto.
- `updates/X_Y_Z.sh`: migracións incrementais para instalacións antigas.
- `updates/X_X_X.sh.example`: plantilla para crear unha migración.
- `.local/share/gallaecia-dots/scripts/modules/`: API Bash pública cargada polo `.bashrc`, con helpers de aplicacións, comandos, ficheiros, rede, interface e o dispatcher `gallaecia`.
- `.local/share/gallaecia-dots/scripts/internal/`: librarías internas de instalación de aplicacións e versións, cargadas explicitamente polo instalador e por todos os updates, pero nunca polo `.bashrc`.
- `.local/share/gallaecia-dots/scripts/system-update.sh`: actualizador interactivo do sistema e dos dotfiles.
- `.local/share/applications/`: overrides mínimos que ocultan do launcher
  utilidades técnicas instaladas como dependencias.
- `.config/bashrc/`: módulos base e espazo de personalización do usuario, cargados por orde numérica.
- `optional/.local/share/gallaecia-dots/bashrc/`: comandos Bash opcionais que só se instalan coa aplicación correspondente.
- `.local/share/gallaecia-dots/hypr/gallaecia.lua`: base de Hyprland controlada polo proxecto.
- `.config/hypr/hyprland.lua`: wrapper de Hyprland que recibe as aplicacións escollidas e deixa espazo para personalización.
- `.config/noctalia/gallaecia.toml`: configuración de Noctalia controlada polo proxecto.
- `.config/noctalia/custom.toml`: configuración persoal, creada só cando non existe.
- `.config/`: outras configuracións base do escritorio.
- `optional/`: configuracións que só se instalan cando se escolle a aplicación correspondente.
- `others/`: ficheiros de sistema para `greetd`, a súa pila PAM e Noctalia Greeter.
- `archinstall/user_configuration.json`: perfil para preparar unha instalación base de Arch.
- `.wallpapers/`: fondos distribuídos polo proxecto.

## Fluxo de instalación e versións

`install.sh` admite tres fluxos efectivos:

- `install`: executa `updates/base.sh` para unha instalación nova.
- `update`: executa, por orde de versión, as migracións aínda non rexistradas.
- `reinstall`: limpa o estado de versións e volve aplicar a base.

O repositorio de instalación e actualización sincronízase sempre desde a rama
`release`. Non engadas opcións, argumentos nin variables de contorno para
escoller outra rama nos scripts ou no comando `gallaecia`.

O estado gárdase en `~/.local/share/gallaecia-dots/`:

- `versions-instaladas`: unha versión aplicada por liña.
- `version`: última versión aplicada.
- `instalado`: data da última instalación ou actualización.

Os nomes `updates/1_0_4.sh` convértense en versións `1.0.4`. O instalador só executa ficheiros co patrón numérico esperado e ordénaos por versión.

Emprega versionado semántico para escoller a seguinte versión:

- Incrementa o parche (`1.0.4` → `1.0.5`) para correccións pequenas que non engaden unha capacidade relevante.
- Incrementa a versión menor (`1.0.4` → `1.1.0`) para grupos amplos de cambios ou funcionalidade nova compatible, como novas integracións e comandos públicos.
- Reserva a versión maior para cambios incompatibles que requiran unha migración ou decisión explícita do usuario.

### Regra fundamental da base e das actualizacións

`updates/base.sh` debe instalar sempre o estado final máis actualizado. Non é unha versión antiga sobre a que se reproducen todas as migracións.

Ao engadir, por exemplo, `updates/1_0_4.sh`:

1. Engade á migración os cambios necesarios para actualizar unha instalación antiga.
2. Integra eses mesmos resultados en `updates/base.sh` e, cando corresponda, nos dotfiles ou módulos fonte.
3. Unha instalación nova debe obter directamente desde a base o mesmo resultado final que unha instalación antiga despois de aplicar a migración.
4. Tras completar a base, o instalador marca `base` e todas as actualizacións dispoñibles como instaladas.

Non obrigues unha instalación nova a reproducir migracións históricas. Evita tamén aplicar un cambio só na migración: iso deixaría as instalacións novas desactualizadas.

As migracións deben poder aplicarse secuencialmente, reutilizar os módulos compartidos e modificar só o necesario. Usa `updates/X_X_X.sh.example` como punto de partida e mantén nela un changelog breve e comprensible.

Todos os updaters `updates/X_Y_Z.sh`, incluída a plantilla
`updates/X_X_X.sh.example`, deben conservar exactamente a mesma estrutura:

1. Constantes, validación e carga de todos os módulos públicos de
   `scripts/modules/` e todas as librarías de `scripts/internal/`, aínda que a
   migración concreta non empregue algunha delas.
2. Unha función pequena por cada instalación, copia ou configuración.
3. `show_changelog()` para o resumo visible.
4. `apply_update()` como orquestrador, comprobando cada función con `if ! funcion; then return 1; fi`.
5. `main()` para confirmar, executar e comunicar o resultado.

Non concentres varias operacións nunha cadea `comando && comando || return 1`. A separación en funcións e os bloques `if` explícitos deben deixar claro que paso fallou e garantir que a versión non se marque cando quede unha acción incompleta.

`install.sh` e as cabeceiras dos updates deben manter sempre o mesmo estándar
despois de que o repo estea dispoñible: declarar `MODULES_DIR` e `INTERNAL_DIR`,
comprobar que se poden ler `apps.sh`, `commands.sh`, `files.sh`,
`gallaecia.sh`, `network.sh` e `ui.sh` dentro de módulos, comprobar tamén
`apps.sh` e `versions.sh` dentro de internal, e facer `source` explícito dos
oito ficheiros con cadanseu comentario de ShellCheck. Non retires unha carga
por non ser necesaria nese momento; a dispoñibilidade uniforme de todos os
helpers é intencionada.

## Separación entre base e personalización

Respecta a propiedade de cada ficheiro:

- A base actualizable vive principalmente en `~/.local/share/gallaecia-dots`.
- `merge_path` copia unha árbore sen borrar o destino e úsase onde pode existir estado que se debe conservar.
- `replace_path` elimina e substitúe unha árbore completa.
- `replace_file` substitúe un ficheiro concreto.
- `gallaecia.toml` está controlado polo proxecto; `custom.toml` non se debe sobrescribir se xa existe.
- O wrapper `~/.config/hypr/hyprland.lua` carga a base compartida de Hyprland. Conserva os placeholders `{{terminal}}`, `{{editor}}`, `{{ide}}`, `{{navegador}}` e `{{explorador_de_arquivos}}` ata que o instalador os substitúa.
- `.bashrc` está controlado polo proxecto. A personalización do usuario debe ir en ficheiros `~/.config/bashrc/NNN-nome`.
- Os ficheiros xa existentes en `~/.config/bashrc/` considéranse personalización do usuario. Non os substitúas nunha migración: mesmo os módulos creados inicialmente por Gallaecia poden ter cambios persoais.
- Os Bashrc opcionais de `~/.local/share/gallaecia-dots/bashrc/` pertencen á aplicación correspondente. Actualízaos só cando esa aplicación estea instalada ou seleccionada.

Antes de cambiar unha operación de copia, comproba se o destino está pensado para ser controlado por Gallaecia ou para conservar cambios do usuario. Non substitúas unha operación `merge_path` por `replace_path` sen unha razón explícita.

## Aplicacións

Cada categoría defínese nunha función `install-category-<categoría>()` de
`scripts/internal/apps.sh`. A propia función contén as súas entradas neste
formato:

```text
tipo|Nome visible|paquetes|comando
```

Os tipos admitidos son:

- `pkg`: paquete de Pacman ou AUR instalado con `yay`.
- `flatpak`: identificador de Flathub.
- `pipx`: paquete Python instalado con `pipx`.

O campo de paquetes pode conter varios nomes separados por espazos. O comando
úsase nas categorías que actualizan Hyprland. Os ficheiros `.desktop` e os MIME
decláranse explicitamente no `case` de cada aplicación dentro da mesma función.

Antes do selector, todas as categorías separan as variantes completas xa
instaladas e móstranas baixo `Xa instaladas:`. Unha variante con varios paquetes
só se considera instalada cando están todos presentes co xestor declarado; as
variantes incompletas seguen dispoñibles para instalar. As xa instaladas
ocúltanse do selector de novas aplicacións, pero únense ás novas para a elección
predeterminada posterior. As categorías principais esixen polo menos unha
selección ou variante xa instalada cando `base.sh` as chama con `--required`;
desde `gallaecia install-category` todas poden cancelarse. Cada función
selecciona, instala e configura as súas aplicacións antes de retornar: non hai
colas nin contexto global entre categorías. Ao engadir unha aplicación:

- Engade a entrada e todo o seu comportamento á función da categoría. Prefire
  un `case` explícito por aplicación para Hyprland e MIME, mesmo cando varias
  aplicacións repitan as mesmas asociacións.
- Instala a selección mediante os modos directos `yay-install --packages`,
  `flatpak-install --packages` e `pipx-install --packages`.
- Instala configuración opcional só se a aplicación foi escollida.
- Nas categorías homoxéneas, para fusionar MIME aplica primeiro as aplicacións
  secundarias e por último a predeterminada: así os tipos exclusivos quedan coa
  súa aplicación e os compartidos quedan asignados á predeterminada.
- Nas categorías heteroxéneas non pidas unha predeterminada común. Aplica os
  MIME de cada app na orde estable das entradas; se existe unha coincidencia,
  a última regra aplicada queda como valor inicial e o usuario pode cambiala.
- Cando unha categoría homoxénea actualiza MIME e Hyprland, usa unha única
  elección predeterminada para ambos. A actualización debe funcionar tanto cos
  placeholders iniciais como con valores xa substituídos.
- Yazi usa `yazi.desktop` para `inode/directory` e o comando literal
  `$TERMINAL -e yazi` en Hyprland.
- `updates/base.sh` chama directamente as funcións de categoría. O menú de
  `gallaecia install-category` declara manualmente as mesmas categorías e
  chama as funcións da versión instalada sen `--required`, repetindo o menú ata
  Esc. Este comando non sincroniza o repositorio: as novas categorías e
  aplicacións só aparecen despois de aplicar a actualización correspondente.
- Conserva a orde intencionada das opcións; a primeira adoita ser a recomendada.
- Actualiza no mesmo cambio a lista de categorías e aplicacións do
  `README.md`, indicando o xestor e os identificadores reais dos paquetes.

## Rede e NetworkManager

Noctalia é a interface para as operacións diarias que xa ofrece, como Wi-Fi,
estado e activación de VPN. `scripts/modules/network.sh` completa unicamente a
administración de perfís que non está dispoñible na interface.

- Emprega `nmcli` e identifica internamente as conexións por UUID. Os nomes son
  só etiquetas visibles e poden estar repetidos.
- Non engadas wrappers que dupliquen unha operación xa resolta por Noctalia sen
  unha vantaxe concreta.
- Non imprimas contrasinais, claves privadas nin o contido completo dun perfil.
- Importar un protocolo require o plugin correspondente de NetworkManager. A
  base garante NetworkManager e OpenVPN; outros plugins son opcionais.
- Para iniciar automaticamente unha VPN clásica usa o seu UUID en
  `connection.secondaries` da conexión base. NetworkManager non implementa
  `connection.autoconnect` para perfís VPN.
- Eliminar perfís ou sobrescribir unha exportación require confirmación
  explícita. Cancelar non debe modificar NetworkManager nin os ficheiros.
- Mantén no README todos os comandos públicos deste módulo e explica cales
  limitacións pertencen a NetworkManager, como a exportación de WireGuard.

## Convencións de Bash

- Prioriza código explícito, lineal e fácil de modificar a man sobre
  abstraccións moi optimizadas. É aceptable repetir bloques pequenos, `case` ou
  chamadas cando iso permite ver nun único lugar todo o comportamento dunha
  categoría ou fluxo.
- Non extraías helpers xenéricos só para reducir duplicación. Faino cando
  eliminen unha cantidade importante de código sen ocultar que función se chama,
  que estado recibe, que ficheiros modifica nin que casos atende.
- Prefire unha función clara por responsabilidade ou categoría fronte a un
  orquestrador que dependa de contexto global, colas, variables preparadas por
  fases anteriores ou múltiples táboas indirectas. A persoa que edite o script
  debe poder seguir o fluxo de arriba abaixo sen saltar repetidamente entre
  funcións.
- Se hai que escoller entre unha implementación algo máis longa e outra máis
  compacta pero difícil de entender, escolle a máis explícita. Neste proxecto a
  facilidade de revisión e ampliación é máis importante ca minimizar liñas ou
  eliminar toda duplicación.
- Usa Bash e conserva os shebangs existentes.
- Nas funcións internas e variables locais usa `snake_case`; reserva maiúsculas para constantes e arrays globais de configuración. Os comandos públicos cargados no Bashrc poden usar nomes con guión, como `git-branch-delete`. As funcións internas `install-category-*` son a excepción intencionada: o seu nome común fai visible que son os puntos de entrada das categorías.
- Declara variables de función con `local`.
- Cita as expansións de variables e rutas salvo cando a separación en palabras sexa deliberada, como no campo de paquetes das entradas de aplicacións.
- Os scripts principais usan `set -u` e `set -o pipefail`. Non introduzas `set -e` sen revisar todo o control explícito de erros.
- Escribe as condicións e validacións con bloques explícitos `if ...; then ...; fi`. Non uses construcións como `[ condición ] || { ...; }` para simular un `if`; son máis difíciles de ler. Pódese conservar `comando || return` ou `comando && seguinte_comando` cando sexa unha propagación curta e directa.
- Ten en conta que `fail` imprime a mensaxe e remata o proceso con código 1.
- Reutiliza `has_command`, `has_package`, `replace_file`,
  `replace_path`, `merge_path` e os wrappers de `gum` antes de crear
  alternativas.
- Engade `# shellcheck source=/dev/null` nas cargas dinámicas cando corresponda.
- Engade comentarios antes de cada función e alias. Nas funcións triviais chega
  con explicar o propósito; nas que reciben estado, modifican globais, teñen
  varios `case` ou forman parte dun fluxo, documenta tamén entradas, saída,
  efectos laterais, relación coa fase anterior/seguinte e por que unhas
  categorías ou casos aparecen e outros non.
- Comenta tamén regex, formatos especiais, expansións de parámetros, separación mediante NUL ou tabuladores e calquera bloque que non resulte evidente nunha primeira lectura. Non describas liña por liña o código trivial.

### Formato dos módulos e comandos Bash

Mantén o mesmo formato nos módulos compartidos e nos Bashrc:

- Se un ficheiro expón varios comandos, centraliza os textos nunha función privada `_nome_help()` e fai que cada comando chame a súa sección.
- Mantén en inglés os nomes dos comandos públicos; as axudas, descricións,
  mensaxes e inputs continúan en galego.
- Todos os comandos públicos deben procesar opcións cun `while (($#)); do` e un `case "$1" in`, mesmo cando inicialmente só admitan `-h|--help` e `--`. A estrutura uniforme facilita engadir opcións no futuro.
- `-h|--help` debe usar sempre o mesmo formato, con seccións en maiúsculas e
  nesta orde: `USO`, `DESCRICIÓN`, `PARÁMETROS` cando existan, `OPCIÓNS`,
  `CONTROIS` cando a interacción teña teclas non evidentes, `RESULTADO`,
  `EXEMPLOS` e `COMANDO ORIXINAL` cando exista passthrough.
- En `USO`, escribe os nomes substituíbles en maiúsculas. Usa `VALOR` para un
  parámetro obrigatorio, `[VALOR]` para un opcional, `VALOR...` para un
  repetible e `[-- ARGUMENTOS DE COMANDO]` para o passthrough.
- `DESCRICIÓN` debe explicar brevemente o propósito e o comportamento
  relevante do wrapper. `PARÁMETROS` e `OPCIÓNS` deben listar cada elemento
  nunha liña propia cunha explicación clara, sen mesturar os argumentos do
  wrapper cos do comando orixinal.
- `RESULTADO` debe indicar que produce ou modifica a función e os códigos de
  saída relevantes. `EXEMPLOS` debe incluír polo menos un uso habitual e outro
  coas opcións máis útiles cando corresponda.
- `CONTROIS` debe explicar as teclas necesarias para navegar, marcar e
  confirmar cando non sexan evidentes, especialmente nos selectores múltiples.
- `COMANDO ORIXINAL` debe explicar a que comando se reenvía o situado despois
  de `--` e mostrar como consultar a súa axuda cando realmente funcione.
- `--` remata as opcións do wrapper. Garda todo o posterior nun array local, normalmente `original_args=("$@")`, e reenvíao ao comando orixinal. Así `wrapper -- --help` mostra a axuda do programa real.
- Se o helper combina varios comandos ou non pode reenviar argumentos de forma coherente, non inventes passthrough. Documenta esta limitación na súa axuda e ofrece só opcións propias útiles, como `--dry-run`.
- As opcións descoñecidas antes de `--` deben producir unha mensaxe clara que indique como consultar `--help`.
- Prefire repetir un parser curto dentro de cada comando antes que ocultar o fluxo en helpers xenéricos difíciles de seguir. Extrae funcións privadas cando aforren unha cantidade importante de código e sigan sendo evidentes, como os selectores compartidos de contedores ou imaxes.
- Mantén os helpers específicos no ficheiro da aplicación que os utiliza. Non movas lóxica exclusiva de Git, Docker, yt-dlp ou SpotDL a módulos globais.
- Os módulos internos de aplicacións e versións deben advertir claramente que
  non son unha API para comandos personalizados. Os helpers reutilizables son
  os de aplicacións, interface, ficheiros, comandos e rede.
- Conserva en `scripts/modules/` só helpers públicos seguros para cargar en cada shell. As librarías exclusivas do instalador deben vivir en `scripts/internal/` e cargarse explicitamente desde `~/.dotfiles`.
- O módulo público `gallaecia.sh` expón só a función `gallaecia`; os seus
  helpers comezan por `_gallaecia_`. Calquera carga de `scripts/internal/`
  iniciada desde ese comando debe facerse nun subshell para non deixar
  funcións, arrays nin variables internas na terminal do usuario.
- Ao engadir, retirar ou renomear un comando, función ou alias público,
  actualiza no mesmo cambio a referencia do `README.md`. Indica tamén a
  aplicación e categoría necesarias cando o comando pertenza a un Bashrc
  opcional.

### Documentación pública

O `README.md` funciona tamén como referencia de uso e debe manter sempre:

- Un índice sincronizado con todos os seus apartados e subapartados.
- A lista completa das categorías e aplicacións de
  `scripts/internal/apps.sh`, co
  xestor e os identificadores de paquete correspondentes.
- A lista completa de comandos, funcións e alias públicos dos módulos e dos
  Bashrc opcionais, cunha descrición breve e a súa dispoñibilidade.
- As guías de actualización, fondos e personalización aliñadas co
  comportamento real da configuración e dos scripts.

Revisa estas catro partes no mesmo cambio sempre que se modifiquen os
encabezados do README, a selección de aplicacións, a API pública, os comandos
opcionais ou os fluxos de uso documentados.

### Operacións interactivas e destrutivas

- Usa os wrappers de `gum` para inputs, seleccións, filtros, mensaxes e confirmacións.
- Despois de seleccionar recursos para borrar, pide sempre unha confirmación Si/No antes de executar a operación.
- Usa unha segunda confirmación cando a acción sexa forzada ou poida eliminar datos importantes, por exemplo volumes, commits non integrados ou contedores activos.
- Cancelar unha selección ou confirmación debe saír sen executar a acción destrutiva.
- Nos desinstaladores de aplicacións, conserva a limpeza proporcionada polo
  propio xestor e limita os efectos colaterais: Yay usa `-Rns` e só limpa a
  caché global cunha opción explícita; Flatpak limpa os runtimes sen uso e pide
  unha segunda confirmación para `--delete-data`; Pipx deixa que `uninstall`
  retire o contorno e os accesos da aplicación sen purgar recursos globais.

## Interface e idioma

A interface interactiva está centralizada en `modules/ui.sh` e usa `gum`. Emprega os wrappers `gum_style`, `info`, `title`, `warning`, `success`, `fail`, `gum_confirm`, `gum_choose`, `gum_input`, `gum_filter` e `gum_write` para conservar o estilo e as cores xeradas por Noctalia.

- O espazado visual pertence aos wrappers de UI. `title` separa a sección anterior e posterior; `gum_confirm`, `gum_choose`, `gum_input` e `gum_write` engaden sempre unha liña baleira antes da interacción. `gum_filter` non engade padding porque ocupa a pantalla completa.
- Implementa ese espazado co `--padding` de Gum, non con `echo`: o padding
  forma parte da interface e Gum elimínao ao pechala, mentres que un `echo`
  deixa liñas baleiras permanentes. Non engadas un `echo` antes destes helpers
  só para crear espazo.
- `gum_choose`, `gum_input`, `gum_filter`, `gum_write`, `gum_file` e
  `gum_folder` expoñen `--header TEXTO` como opción propia. Nos consumidores,
  sitúa esta opción antes de `--` e deixa despois de `--` unicamente os
  argumentos reenviados ao subcomando orixinal de Gum.
- Define as cores de Gum mediante roles semánticos xenéricos compartidos por
  todos os wrappers, non con variables específicas para cada subcomando. Se
  engades un rol novo en `ui.sh`, expórtao tamén en
  `noctalia/ui-colors.sh.template` e reutilízao en todos os controis
  equivalentes.

Escribe en galego as mensaxes novas e revisa a ortografía antes de rematar. Conserva a orde de idiomas do sistema:

```text
Galego -> Español -> Inglés
```

Non codifiques cores novas directamente nun fluxo se poden formar parte do módulo de UI ou do template de Noctalia.

## Configuración do escritorio

- Hyprland está configurado mediante Lua, non mediante o formato tradicional `.conf`.
- A configuración común debe ir en `.local/share/gallaecia-dots/hypr/gallaecia.lua`; o wrapper debe quedar pequeno e personalizable.
- Noctalia é a peza central da barra, launcher, portapapeis, capturas, multimedia, fondo e actualizacións.
- As paletas dinámicas de `gum` xéranse con `.local/share/gallaecia-dots/noctalia/ui-colors.sh.template`.
- En `[theme.templates]` de Noctalia conserva só os templates estruturais do
  núcleo e os das aplicacións ofrecidas nas categorías de `internal/apps.sh`.
  Non habilites templates de programas que Gallaecia non instala nin permite
  seleccionar.
- As configuracións opcionais de terminais, Yazi, SpotDL e yt-dlp deben permanecer dentro de `optional/` mentres dependan da selección do usuario.
- `~/.config/code-flags.conf` é unha configuración opcional controlada por
  Gallaecia para VS Code. Instálaa só cando VS Code estea seleccionado ou xa
  instalado e mantén nela `--password-store=gnome-libsecret` para usar GNOME
  Keyring mediante Secret Service.
- `~/.config/electron-flags.conf` é unha configuración controlada por Gallaecia
  para todas as aplicacións que usan os wrappers `electronXX` de Arch.
  Instálaa sempre desde a base e mantén nela
  `--password-store=gnome-libsecret`, porque Electron non detecta
  automaticamente GNOME Keyring cando o escritorio é Hyprland. As aplicacións
  que non usan eses wrappers poden requirir o seu propio ficheiro de flags.
- Conserva os nomes galegos dos directorios XDG e calquera ruta que dependa deles.
- `others/pam/greetd` é o template controlado para `/etc/pam.d/greetd`.
  Conserva a pila predeterminada de Arch e as dúas regras
  `pam_gnome_keyring.so`; calquera cambio debe revisarse como configuración de
  autenticación sensible.
- Non habilites nin inicies directamente `gnome-keyring-daemon.service` desde
  Gallaecia. O paquete de Arch habilita globalmente o seu socket e PAM entrega
  o contrasinal no login; habilitar tamén o servizo no usuario pode facer que
  enumere os chaveiros antes de crear `Login` no primeiro acceso. As migracións
  poden deshabilitar o servizo sen detelo para retirar symlinks antigos. Unha
  migración correctiva pode reiniciar puntualmente o daemon, sen habilitalo,
  cando sexa necesario rexenerar `login.keyring`.
- Os overrides de `.local/share/applications/` deben conservar exactamente o
  nome do `.desktop` de `/usr/share/applications/` e conter só `[Desktop Entry]`,
  `Type`, `Name` e `Hidden=true`, o mínimo que valida freedesktop. Instálaos
  mediante unha fusión que non elimine outros overrides persoais.

## Comprobacións seguras

Non hai unha suite automatizada de probas. Fai comprobacións estáticas proporcionais aos ficheiros modificados:

```bash
bash -n install.sh updates/*.sh \
  .local/share/gallaecia-dots/scripts/*.sh \
  .local/share/gallaecia-dots/scripts/modules/*.sh \
  .local/share/gallaecia-dots/scripts/internal/*.sh \
  .bashrc .config/bashrc/* \
  optional/.local/share/gallaecia-dots/bashrc/*
```

Se ShellCheck está instalado, execútao sobre os scripts Bash modificados. Valida tamén segundo o formato:

- TOML cun parser TOML.
- JSON cun parser JSON.
- Lua con `luac -p` cando estea dispoñible.

Revisa ademais con `git diff --check` que non se introducisen erros de espazos.

Non executes como proba `install.sh`, `updates/base.sh`, unha migración real nin `system-update.sh` no equipo de traballo. Estes scripts poden instalar paquetes, borrar ou substituír configuracións, modificar `/etc`, habilitar servizos e reiniciar o sistema. Se unha proba de integración fose imprescindible, require un contorno Arch illado e autorización explícita.

## Revisión antes de rematar

Antes de entregar un cambio:

1. Comproba se afecta tanto á instalación nova como ás existentes.
2. Se creaches unha migración, confirma que o resultado tamén está integrado na base actualizada.
3. Verifica que non se sobrescribe personalización ou estado do usuario por accidente.
4. Revisa paquetes, comandos, ficheiros `.desktop`, asociacións MIME e placeholders relacionados.
5. Executa as validacións estáticas aplicables.
6. Actualiza o `README.md` cando cambie o comportamento visible, os requisitos, as categorías ou o proceso de instalación.
7. Se se crea ou modifica unha regra de estilo, formato ou estrutura, actualiza
   `AGENTS.md` no mesmo cambio para mantelo como fonte de verdade.
8. Resume que se cambiou, como se validou e que non se puido probar de forma segura.
