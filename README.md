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
- Desenvolvemento
- Rede e privacidade
- Descargas e personalización

Moitas categorías permiten escoller varias opcións, e nalgúns casos tamén definir unha app por defecto.

## 🚀 Instalación

> [!WARNING]
> O instalador modifica e substitúe diferentes ficheiros de configuración do sistema e do usuario.
>
> Recoméndase utilizar Gallaecia Dots sobre unha instalación limpa de Arch Linux, sen entorno gráfico previo.

Executa:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/XurxoMF/gallaecia-dots/main/install.sh)
```

O instalador guiarate paso a paso cunha interface interactiva.

> [!IMPORTANT]
> Se tras reiniciar o sistema ao rematar a instalación che aparece un erro de Hyprland ou algunha app non funciona correctamente reinicia de novo ou cambia o fondo de pantalla seleccionando o mesmo ou un novo para que Noctalia xere as paletas de cores correctamente.

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
