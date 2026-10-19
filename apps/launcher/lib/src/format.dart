const _days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
const _months = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

String formatTime(DateTime t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

String formatDate(DateTime t) => '${_days[t.weekday - 1]}, ${t.day} de ${_months[t.month - 1]}';

String greetingFor(DateTime t) => t.hour < 12
    ? 'BUENOS DÍAS'
    : t.hour < 19
        ? 'BUENAS TARDES'
        : 'BUENAS NOCHES';
