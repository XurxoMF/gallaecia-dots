# 🌿 Gallaecia Dots

### Arch + Hyprland. En galego. Á túa maneira.

Un conxunto de dotfiles e un instalador interactivo para crear rapidamente un escritorio baseado en **Arch Linux + Hyprland**, cunha identidade galega e sen decidir por ti como debes usar o teu sistema.

## 🐚 Que é Gallaecia Dots?

**Gallaecia Dots** é un conxunto de dotfiles para **Arch Linux + Hyprland**, deseñado e configurado integramente en galego.

Inclúe unha configuración visual lista para usar, fondos de pantalla con temática galega e unha selección mínima de compoñentes necesarios para ter un escritorio funcional.

Pero Gallaecia Dots **non pretende ser unha distribución nin un sistema pechado**.

O seu obxectivo é servir como punto de partida rápido para instalar Arch + Hyprland mantendo unha idea moi simple:

**O sistema é teu. A configuración é túa. Ti decides que instalar e como mantelo.**

## 🧭 Un enfoque non opinionated

Moitos dotfiles instalan unha colección completa de aplicacións, ferramentas e configuracións escollidas polo seu autor.

Gallaecia Dots intenta evitar iso.

Durante a instalación poderás escoller que aplicacións queres instalar para diferentes tarefas:

- Navegador web
- Explorador de arquivos
- Editor de texto ou código
- Visualizador de imaxes
- Reprodutor de vídeo
- Visor de PDF
- Xestor de arquivos comprimidos
- Xestor de discos e particións
- Calculadora
- Cliente de correo
- Suite ofimática
- Aplicación de notas
- E outras ferramentas opcionais

Non queres instalar nada dunha categoría?

**Simplemente sáltaa.**

Gallaecia Dots só instala obrigatoriamente os compoñentes necesarios para que o escritorio e a configuración funcionen correctamente, como **Hyprland, Noctalia, XDG Desktop Portals e outras dependencias básicas do sistema**.

## 🌿 Feito en galego

Gallaecia Dots está pensado arredor do galego.

O instalador, as configuracións propias e o escritorio utilizan o galego como idioma principal.

Durante a instalación, configurarase o sistema co seguinte orde de idiomas:

```text
Galego → Español → Inglés
```

Deste xeito, cando unha aplicación non dispoña de tradución ao galego, o sistema intentará utilizar primeiro o español e posteriormente o inglés.

Os fondos de pantalla incluídos por defecto tamén están inspirados en Galicia e na súa identidade.

## 📦 Que instala?

A instalación divídese en dúas partes.

### Compoñentes obrigatorios

Instálanse os paquetes e configuracións mínimos necesarios para que Gallaecia Dots funcione correctamente.

Entre eles:

- Hyprland
- Noctalia
- Noctalia Greeter
- XDG Desktop Portals
- PipeWire
- Kitty
- Flatpak
- yay
- Configuración GTK e Qt
- XDG User Directories
- Tipografías necesarias
- Servizos e dependencias básicas do escritorio

### Aplicacións opcionais

O instalador preguntará que aplicación queres utilizar para cada categoría.

Podes escoller unha das opcións dispoñibles ou **non instalar ningunha**.

Gallaecia Dots non intenta construír o sistema por ti.

**Só che axuda a construílo máis rápido.**

## 🚀 Instalación

> [!WARNING]
> O instalador modifica e substitúe diferentes ficheiros de configuración do sistema e do usuario.
>
> Durante a instalación indicarase que ficheiros ou directorios serán afectados antes de realizar os cambios.
>
> Recoméndase utilizar Gallaecia Dots sobre unha instalación limpa de Arch Linux SIN entorno gráfico, puro texto.

Executa:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/XurxoMF/gallaecia-dots/main/install.sh)
```

O instalador guiarate paso a paso mediante unha interface interactiva.

Só tes que responder ás preguntas e deixar que ocorra a **maxia pagá**.

## 🔧 Despois da instalación

Gallaecia Dots **non é un sistema de configuración xestionado nin actualizable automaticamente**.

Unha vez instalada unha versión dos dotfiles:

- Os ficheiros pasan a formar parte do teu sistema.
- Podes editalos libremente.
- Podes eliminar o que non precises.
- Podes engadir as túas propias configuracións.
- Ti es responsable de manter a configuración compatible coas actualizacións do sistema.

As futuras versións de Gallaecia Dots **non actualizarán automaticamente unha instalación existente** se non que correxirán ou mellorarán cousas para **as novas instalacións**.

Isto é intencionado.

O proxecto está pensado como un **instalador rápido e un punto de partida**, non como unha capa de xestión permanente sobre Arch Linux.

Instálalo. Personalízalo. Rómpeo. Arránxao.

**É o teu sistema.**

O que si se proporcionará entre versións é un **changelog** para que poidas manterte ao día cos cambios realizados si así o desexas.

Nestes changelogs atoparás as aplicacións novas ou eliminadas, cambios nos arquivos de configuración, novos arquivos como fondos de pantalla, bashrc...

Ti serás responsable de agregar estes cambios manualmente.

## ⚠️ Estado do proxecto

Gallaecia Dots é un proxecto persoal en desenvolvemento.

Pode haber cambios importantes entre versións e algunhas actualizacións de Arch Linux, Hyprland ou outros compoñentes poden requirir cambios manuais na configuración.

Se algo rompe:

**Benvido a Arch.** 🫡

## 🤝 Contribucións

As propostas, correccións e melloras son benvidas.

Podes abrir unha issue ou enviar unha pull request a través de GitHub.

## 📜 Licenza

Baixo a licenza MIT calquera poderá facer o que queira con este contido. Agradecería que si fas un fork ou algo similar me mencionaras como autor orixinal ♥️
