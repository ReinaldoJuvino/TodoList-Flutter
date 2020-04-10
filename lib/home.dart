
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List _listaTarefas = [];
  //map que guarda o ultimo removido para ser buscado pela snackBar.desfazer
  Map<String,dynamic> _ultimoExcluido = Map();

  TextEditingController _controllerStatusTarefa = TextEditingController();
  //encontra o diretorio onde ficara o arquivo e retorna seu endereço 
  Future<File> _getFile() async{
    final diretorio = await getApplicationDocumentsDirectory();
    return File("${diretorio.path}/dados.jsom");
  }
  //adiciona toda a lista no arquivo 
  _salvarArquivo() async {

    var arquivo = await _getFile();
    String dados = json.encode(_listaTarefas);
    arquivo.writeAsString(dados);
    
  }
  //adiciona a tarefa a list 
  _salvarTarefa(){

    String textoDigitado = _controllerStatusTarefa.text;
    Map<String,dynamic> tarefa = Map();
    tarefa["titulo"] = textoDigitado;
    tarefa["realizada"] = false;
    setState(() {
      _listaTarefas.add(tarefa);
    });
    
    _salvarArquivo();
    _controllerStatusTarefa.text = "";

  }
  //recupera os arquivos 
  _recuperarArquivo()async{

    try{

      final arquivo = await _getFile();
      return arquivo.readAsString();

    }catch(e){
      
      return null;
    }

  }
  //a aplicação iniciara trazendo todos as tarefas salvas na list
  @override
  void initState(){//induz um primeiro estado a aplicação ao ser iniciada
    super.initState();

    _recuperarArquivo().then( (dados){
      setState(() {
        _listaTarefas = json.decode(dados);
      });
    });
  }

  //retona o itemBuilder junto com o dismissible
  Widget criarItemLista(context,index){
    //ideal seria gerar uma chave que não se repita dentro da aplicação
    return Dismissible(  
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      //definido o sentido do movimento
      direction: DismissDirection.endToStart,
      onDismissed: (direction){
        // recuperando item removido
        _ultimoExcluido = _listaTarefas[index];
        
        //index se refere a o item atual que esta selecionando
        _listaTarefas.removeAt(index);
        //salvando novamente vc irá sobreescrever o arquivo
        _salvarArquivo();
        //snackBar : para utilizar a snackbar devemos recuperar o ultimo item excluido
        final snackbar = SnackBar(
          content: Text("Item excluido com suscesso"),
          //tempo de duração da visibilidade da barra
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: "Desfazer",
            onPressed: (){
              //desfazendo o ultimo item removido.
              //inserindo novamente na list a na posição que estava antes
              setState(() {
                _listaTarefas.insert(index, _ultimoExcluido);
              });
              _salvarArquivo();

            }
          ),
        );
        //tornado a snackBar visivel
        Scaffold.of(context).showSnackBar(snackbar);
        
      },
      background: Container(
        color: Colors.red,
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Icon(
              Icons.delete,
              color: Colors.white,
            )
          ],
        ),
      ),
      //definido qual widget será movido
      child: CheckboxListTile(
        activeColor: Colors.deepPurple[100],
        checkColor: Colors.deepPurple,
        //recuperanto o nome da tarefa 
        title: Text(_listaTarefas[index]["titulo"]),
        //definindo valor inicial para o chackbox
        value: _listaTarefas[index]["realizada"],
        onChanged: (valorAlterado){
          //atualizando status da tarefa 
          setState(() {
            _listaTarefas[index] ["realizada"] = valorAlterado;
          });
          //apos a mudança no status devemos salvar novamente.
          _salvarArquivo();
        }
      )
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.deepPurple,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.black,
        child: Icon(Icons.add),
        mini: true,
        onPressed: (){

          showDialog(
            context: context,
            builder: (context){

              return AlertDialog(
                title: Text("Adicionar Tarefa"),
                content: TextField(
                  controller: _controllerStatusTarefa,
                  decoration: InputDecoration(
                    labelText: "digite sua tarefa"
                  ),
                  onChanged: (text){

                  },
                ),
                actions: <Widget>[
                  FlatButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancelar")
                  ),
                  FlatButton(
                    onPressed: (){
                      _salvarTarefa();
                      Navigator.pop(context);
                    },
                    child: Text("Salvar")
                  )
                ],
              );
            }
          );
        }
      ),
      body: Column(
         children: <Widget>[
           Expanded(
            child: ListView.builder(
              itemCount: _listaTarefas.length,
              itemBuilder: criarItemLista
            ),
          )
         ],
      ),
    );
  }
}