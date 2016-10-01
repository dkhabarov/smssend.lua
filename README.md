# smssend.lua
smssend - is a program to send SMS messages from the commandline via service http://sms.ru/. (Lua Version). Also smsrulib - Lua bindings for the sms.ru API. Lets you send messages, check their status, find their cost etc.

# Документация утилиты командной строки

## Опции:

* --help — Показать справку по опциям
* --version — Показать версию утилиты
* --login — Устанавливает логин на сервисе sms.ru
* --password — Устанавливает пароль на сервисе sms.ru
* --action — Выбрать действие для запуска. (Подробности ниже)
* --to — Адрес, куда слать сообщения
* --message — Не читать стандартный поток ввода. Будет отправлено сообщение, которое указано в качестве значения данного аргкумента.
* --from — Имя отправителя (Должно быть согласованно с администрацией сервиса sms.ru
* --time — Время отправки, указывается в формате UNIX TIME.
* --translit — Переводить все русские символы в латинские.



## Действия

Основная часть построена на действиях. Допустим, если вы хотите получить баланс, нужно указать действие:
`--action=balance`

Доступные действия:

* send – Отправка сообщения. (Если вы хотите просто отправить сообщение, указывать не обязательно.
* status – Статус отправленного сообщения.
* cost – Возвращает стоимость сообщения на указанный номер и количество сообщений, необходимых для его отправки.
* balance – Получение баланса.
* limit – Получение текущего состояния вашего дневного лимита.
* stoplistadd – На номера, добавленные в стоплист, не доставляются сообщения (и за них не списываются деньги)
* stoplistdel – Удаляет один номер из стоплиста

## Примеры

Практически всегда надо указывать аргументы login и password.
Отправка сообщения, без указания агрумента message на номер 79099999999:

```
$ lua ./smssend.lua --login=79030000000 --password=mysuperpassord --to=79099999999
Hello. This is test sms message. Sent from smssend.lua (New version).
```

Мы будем должны получить сообщение:

>Hello. This is test sms message. Sent from smssend.lua (New version).

Ещё один пример, используя stdin:
```
echo "Hello. This is test sms message. Sent from smssend.lua (New version)." |lua ./smssend.lua --login=79030000000 --password=mysuperpassord --to=79099999999
```

Отправка сообщения используя агрумент message:
```
lua ./smssend.lua --login=79030000000 --password=mysuperpassord --to=79099999999 --message='Hello. This is test sms message. Sent from smssend.lua (New version).'
```

Однако, мы посторались придумать варианты, когда в агрументах явно не надо указывать логин и пароль.
Первый вариант, возможно записать их в ~/.smssendrc:
```
echo '79030000000:mysuperpassord' | tee ~/.smssendrc > /dev/null
chmod 600 ~/.smssendrc
```
После любой из приведённых примеров, без агрументов login & password.
Ещё один вариант:

```
lua ./smssend.lua --to=79099999999 --message='Hello. This is test sms message. Sent from smssend.lua (New version).'
Enter login: 79030000000
Enter password: 
Retype password:
```

Вводимый пароль видно не будет.
Проверка статуса отправленного сообщения.
Сервис возвращает идентификатор каждого отправленного сообщения. Порой мы можем захотетить проверить, доставлено ли оно:

```
lua ./smssend.lua --action=status --message='0000-99'
0000-99: Сообщение не найдено.
```

С реальным сообщением выводимая информация конечно будет по другому…
Проверка стоимости сообщения, и кол-во сообщений, необходимых для его отправки:
```
lua ./smssend.lua --action=cost --message='Hello. This is test sms message. Sent from smssend.lua (New version).' --to=79099999999
Cost: 0.22
SMS Count: 1
```
Проверка баланса:
```
lua ./smssend.lua --action=balance
Balance: 6.43
```
Получение лимитов:

```
lua ./smssend.lua --action=limit
Day limit: 10
Messages (Count) sent today: 0
```

Добавление номера 89093000000 в stop-list:
```
lua ./smssend.lua --action=stoplistadd --to=89093000000 --message=test
```

Удаление номера из stop-list:
```
lua ./smssend.lua --action=stoplistdel --to=89093000000
```



## Возвращаемые коды
Как и большинство утилит командной строки UNIX, утилита smssend.lua обычно завершается с определёнными кодами.

* 0 – Успешно
* 1 – API сервиса верунул ошибку
* 2 – Ошибка использования утилиты.

# Краткая документация модуля



Подключение модуля:
```
smsrulib = require"smsrulib"
```
Инициализация модуля:
```
sms_client = smsrulib.init(login, password)
```
Проверка аутентификации. (Происходит при инициализации на уровне модуля):
```
sms_client:test_auth()
```
Получение хэша sha512(password+token)
```
sms_client:get_crypt_key()
```
Получение токена:
```
sms_client:get_token()
```
Отправка сообщения:
```
sms_client:send(to, text[, from, time, translit, test])
```
Получение статуса отравленного сообщения:
```
sms_client:status(id)
```
Получение стоимости сообщения на указанный номер и количество сообщений, необходимых для его отправки:
```
sms_client:cost(to, message)
```
Получение баланса:
```
sms_client:balance()
```
Получение текущих лимитов:
```
sms_client:limit()
```
Добавление номера to в stop-list c причиной reason:
```
sms_client:stoplist_add(phone, reason)
```
Удаление номера из stop-list:
```
sms_client:stoplist_del(phone)
```
