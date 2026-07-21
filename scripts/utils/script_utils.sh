##############
#  UI UTILS  #
##############

#--------#
# COLORS #
#--------#

bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)

red=$(tput setaf 1)
green=$(tput setaf 76)
blue=$(tput setaf 69)
purple=$(tput setaf 104)
orange=$(tput setaf 215)

#-------------------#
# OUTPUT FORMATTING #
#-------------------#

e_header() {
    printf "\n${bold}${orange}==========  %s  ==========${reset}\n" "$@"
}

e_arrow() {
    printf "➜ $@\n"
}

e_success() {
    printf "${green}✔ %s${reset}\n" "$@"
}

e_error() {
    printf "${red}✖ %s${reset}\n" "$@"
}

e_warning() {
    printf "${purple}➜ %s${reset}\n" "$@"
}

e_underline() {
    printf "${underline}${bold}%s${reset}\n" "$@"
}
e_bold() {
    printf "${bold}%s${reset}\n" "$@"

}

e_note() {
    printf "${underline}${bold}${blue}Note:${reset}  ${blue}%s${reset}\n" "$@"
}
