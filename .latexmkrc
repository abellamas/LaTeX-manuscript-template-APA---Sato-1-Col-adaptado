# Configuracion de latexmk. Con este archivo en el directorio alcanza con
# correr  latexmk  a secas: usa pdflatex, llama a biber cuando hace falta y
# deja TODO lo generado en build/, incluido el PDF.
#
#   latexmk           compila
#   latexmk -pvc      recompila solo al guardar
#   latexmk -c        borra los auxiliares y deja el PDF
#   latexmk -C        borra tambien el PDF

# Sin esto, latexmk a secas intentaria compilar TODOS los .tex del
# directorio, incluidos los fragmentos que se cargan con \input.
@default_files = ('main.tex');

$pdf_mode   = 1;         # 1 = pdflatex (el template usa \usepackage{times})
$out_dir    = 'build';
$bibtex_use = 2;         # corre biber y borra sus auxiliares al limpiar

# ---------------------------------------------------------------------
# PDF de entrega con el nombre que pide la catedra:
#   LA2026-2_Apellido_Titulo del trabajo.pdf
# El titulo sale de \title{...} y el apellido de \author{...} de main.tex.
# Al terminar, latexmk copia build/main.pdf con ese nombre; main.pdf queda
# igual para que la vista previa y el synctex de Workshop sigan andando.
$codigo_entrega = 'LA2026-2';

END {
    local $?;                                   # no tocar el codigo de salida
    my $pdf = 'build/main.pdf';
    return unless -e $pdf;
    require Encode; require Unicode::Normalize; require File::Copy;
    open(my $fh, '<:encoding(UTF-8)', 'main.tex') or return;
    my $tex = do { local $/; <$fh> }; close $fh;
    $tex =~ s/(?<!\\)%.*//g;                    # sacar comentarios
    my ($titulo) = $tex =~ /\\title\{(.*)\}\s*$/m or return;
    my ($autor)  = $tex =~ /\\author\{\s*(?:\\textbf\{)?([^}\\]+)/ or return;
    my $limpiar = sub {
        my $s = shift;
        $s =~ s/\\[A-Za-z]+//g;                 # comandos (\textbf, \Large...)
        $s =~ s/[{}]//g;
        $s = Unicode::Normalize::NFD($s);
        $s =~ s/\p{Mn}//g;                      # tildes fuera (á -> a)
        $s =~ s/[\\\/:*?"<>|]//g;               # caracteres prohibidos en Windows
        $s =~ s/\s+/ /g; $s =~ s/^ | $//g;
        return $s;
    };
    my @nombres  = split / /, $limpiar->($autor);
    my $apellido = $nombres[-1];
    my $destino  = "build/${codigo_entrega}_${apellido}_" . $limpiar->($titulo) . '.pdf';
    return if -e $destino && -M $destino <= -M $pdf;   # ya esta al dia
    File::Copy::copy($pdf, $destino);
}
