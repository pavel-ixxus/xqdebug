

$(document).ready(function() {
         $.ajaxSetup({cache:false});

         $(".resizable").resizable({
              resize: function(event, ui) {
                 $(ui.element).children(":first")
                   .width(ui.element.width()).height(ui.element.height());
              }
              ,
              stop: function( event, ui) {
                var elem = $(ui.element).children(":first");
                $.get("/debug/window.xqy", { winId: elem.attr("id"), width: elem.width(), height: elem.height()} ); 
              }

         } );
} );
