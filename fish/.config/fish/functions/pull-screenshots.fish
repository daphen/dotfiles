function pull-screenshots --description "Rsync latest proart screenshots into ~/proart-screenshots/"
    mkdir -p $HOME/proart-screenshots
    rsync -az --partial --info=progress2 \
        proart:Pictures/Screenshots/ $HOME/proart-screenshots/
end
