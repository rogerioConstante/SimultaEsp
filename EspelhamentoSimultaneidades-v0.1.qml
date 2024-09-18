//=========================================================================================\\
//  Espelhamento de Simultaneidades v0.1                                                   \\
//                                                                                         \\
//  Copyright (C)2024 Rogério Tavares Constante                                            \\
//                                                                                         \\
//  Este programa é um software livre: você pode redistribuir e/ou  modificar              \\
//  ele nos termos da GNU General Public License como publicada pela                       \\
//  Free Software Foundation, seja na versão 3 da licença, ou em qualquer outra posterior. \\
//                                                                                         \\
//  Este programa é distribuído com a intenção de que seja útil,                           \\
//  mas SEM NENHUMA GARANTIA; Veja a GNU para mais detalhes.                               \\
//                                                                                         \\
//  Uma cópia da GNU General Public License pode ser encontrada em                         \\
//  <http://www.gnu.org/licenses/>.                                                        \\
//                                                                                         \\
//=========================================================================================\\

import QtQuick 2.3
import QtQuick.Controls 1.3
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.1
import MuseScore 3.0

MuseScore {
      menuPath: "Plugins.Espelhamento"
      description: "Espelhamento de Simultaneidades.\nPlugin para analisar uma simultaneidade e gerar espelhamentos\n
      considerando cada classe de notas como um eixo."
      version: "0.1"

      Component.onCompleted: {
        if (mscoreMajorVersion >= 4) {
            title = qsTr("Espelhamento de Simultaneidades")
            thumbnailName = "Intervalos.png"
            categoryCode = "Composição"
        }
      }

// ----------------------------------------------------------------------------------------------------------------
   MessageDialog {
      id: msgErros
      title: "Erros!"
      text: "-"
      property bool estado: false
      onAccepted: {
            msgErros.visible=false;
      }

      visible: false;
} // msgErros
// ---- variáveis globais ----
      property var vozes: [];
      property var espelhos: [];
      property var cond: [];
      property bool finaliza: false;

// ----------- funções ---------
function int2pc(st) { // converte intervalo para classe de intervalos
  var i; 
  i = st % 12
  if (i > 6) { i = 12 - i;};
  return i
}

function gerarConjuntos() { console.log("gerar conjuntos")
  function comparar(a, b) {
            return a - b;
        }
  vozes.sort(comparar);
  console.log("vozes", vozes);
  for (var v=0;v<vozes.length;v++) {
    espelhos[v] = inversão(rotateLeft(vozes, v));
  };
}

function inversão(conj) {
  var inversão = [];
  var t = (conj[0] - (12 - conj[0]) % 12); //console.log("t = ", t);
        if (t < 0) t = t + 12;
        for (var x=0;x<conj.length;x++) {
            var inv = ((12 - conj[x]) + t) % 12;
            inversão.push(inv);
        };
        console.log("Inversão:", inversão);
        return inversão;
}
function rotateLeft(arr, times) {
        var count = times % arr.length;
        return arr.slice(count).concat(arr.slice(0, count));
}

function includes(obj, elem) {
   for (x=0;x<obj.length;x++) {
     if (obj[x] == elem) { return true };
   };
   return false;
}

function carregarNotas() {

  console.log("Espelhamento de Simultaneidades....................... Rogério Tavares Constante - 2024(c)")

  if (typeof curScore == 'undefined' || curScore == null) { // verifica se há partitura
     console.log("nenhuma partitura encontrada");
     msgErros.text = "Erro! \n Nenhuma partitura encontrada!";
                       msgErros.visible=true; finaliza = true; return; };

  //procura por uma seleção

  var pautaInicial;
  var pautaFinal;
  var posFinal;
  var posInicial;
  var processaTudo = false;
  vozes = [];
  var cursor = curScore.newCursor();

  cursor.rewind(1);

    if (!cursor.segment) {
       // no selection
       console.log("nenhuma seleção: processando toda partitura");
       processaTudo = true;
       pautaInicial = 0;
       pautaFinal = curScore.nstaves;

     } else {
       pautaInicial = cursor.staffIdx;
       posInicial = cursor.tick;
       cursor.rewind(2);
       pautaFinal = cursor.staffIdx + 1;
       posFinal = cursor.tick;
          if(posFinal == 0) {  // se seleção vai até o final da partitura, a posição do fim da seleção (rewind(2)) é 0.
          							// para poder calcular o tamanho do segmento, pega a última posição da partitura (lastSegment.tick) e adiciona 1.
          posFinal = curScore.lastSegment.tick + 1;
          }
       cursor.rewind(1);
    };

  // ------------------ inicializa variáveis de dados

            var seg = 0;
            var carregou;
            var trilha;
            var trilhaInicial = pautaInicial * 4;
            var trilhaFinal = pautaFinal * 4;

          for (trilha = trilhaInicial; trilha < trilhaFinal; trilha++) {
            // lê as informações da seleção (ou do documento inteiro, caso não haja seleção)
            if(processaTudo) { // posiciona o cursor no início
                  cursor.rewind(0);
            } else {
                  cursor.rewind(1);
            };
            var segmento = cursor.segment;
          //console.log("===========", trilha, trilhaFinal);
           while (segmento && (processaTudo || segmento.tick < posFinal)) {
          //console.log("A", segmento.tick, posFinal)

             // Passo 1: ler as notas e guardar em "vozes"

               	cursor.track = trilha;
            	  if (segmento.elementAt(trilha)) {
                    if (segmento.elementAt(trilha).type == Element.CHORD) {
                      var notas = segmento.elementAt(trilha).notes;
                      for (var j=notas.length-1; j>=0;j--) {
                        var pc = notas[j].pitch % 12;
                        var teste = includes(vozes, pc);
                        if (!teste) { vozes.push(pc); };
                      };
                   };
                 };
              cursor.next(); segmento = cursor.segment;
              //if (segmento) { console.log("B", trilha, segmento.tick, vozes) };
             };



           };


   if (vozes.length == 0) { msgErros.text += "Nenhuma nota carregada!!\n";
                        msgErros.estado=true; (typeof(quit) === 'undefined' ? Qt.quit : quit)(); };

}

function gerarPartitura() {
  // ----------------- cria score com título e subtitulo e compassos em branco
  // Cria um novo score
  var score = newScore("", "guitar", 1);
  var cursor = curScore.newCursor();
  cursor.rewind(0);

  var titulo = "Espelhamento do conjunto: " + vozes;
  //var subtitulo = "em " + numerador + " por " + denominador;
  score.addText("title", titulo);
  var qtdCompass = vozes.length + 1;
  if (score.nmeasures < qtdCompass) {
      score.appendMeasures(qtdCompass-score.nmeasures);
  };
  console.log("-------------------------------------- cria notas ");
  cursor.rewind(0);
  var pos = [];
  for (var x = 0; x < cond.length; x++) {
    pos[x] = cursor.tick;
    cursor.setDuration(4, 4);
    for (var n=0;n<cond[x].length;n++) {
      if (n==0) {
        cursor.addNote(cond[x][n]);
      } else {
        cursor.addNote(cond[x][n], true);
      };
    };
  };
  cursor.rewind(0);
  for (var x=0;x<cond.length;x++){
    while (cursor.tick < pos[x]) { cursor.next(); };
      var nome = newElement(Element.STAFF_TEXT);
      if (x==0) { nome.text = "C."; } else { nome.text = "E. " + x; };
      cursor.add(nome);
  }

  score.endCmd();
}
// ---------------------------------------------------------------------------------------------------------
function conduçãoVozes(){
  cond[0] = [];
  cond[0].push(vozes[0] + 48);
  for (var n=vozes.length-1;n>=1;n--) {
    if (n < vozes.length-1 && vozes[n] < vozes[n+1]) {
      cond[0].push(vozes[n] + 72);
    } else {
      cond[0].push(vozes[n] + 60);
    };
  };
  for (var i=1;i<=espelhos.length;i++){
    cond[i] = [];
    cond[i].push(espelhos[i-1][0] + 48);
    //if (espelhos[i].length <= 1) { continue; };
    for (var n=espelhos[i-1].length-1;n>=1;n--) {
      if (n < espelhos[i-1].length-1 && espelhos[i-1][n] < espelhos[i-1][n+1]) {
        cond[i].push(espelhos[i-1][n] + 72);
      } else {
        cond[i].push(espelhos[i-1][n] + 60);
      };
    };
    console.log("condução de vozes:", cond[i]);
  };
}

// --------------------------------------

  onRun: {

     finaliza = false;
     msgErros.text = "";
     msgErros.estado = false;

     carregarNotas();
     gerarConjuntos();
     conduçãoVozes();
     gerarPartitura();

     if (finaliza) { (typeof(quit) === 'undefined' ? Qt.quit : quit)(); };

  } // fecha onRun
} // fecha função Musescore
