# Запуск ЛР № 3

Нужна база PostgreSQL `restaurant_lab` со схемой `restaurant` из ЛР № 1 и данными из `01_data.sql` ЛР № 2. Если они уже загружены, повторять загрузку не нужно.

## DBeaver

Подключение **«Ресторан — ЛР1 и ЛР2»** (`127.0.0.1:55414`, база `restaurant_lab`). Включите автокоммит и выполните файлы целиком через **Редактор SQL → Выполнить SQL скрипт** (`Option + X`):

1. `01_analytics.sql`
2. `02_views.sql`
3. `03_materialized_view.sql`
4. `04_demo.sql`

В `04_demo.sql` отказ `CHECK OPTION` ожидается и выводится как уведомление. Последний `ROLLBACK` откатывает демонстрационные записи и изменения.

## Терминал

Откройте Docker Desktop, затем выполните:

```bash
cd "$HOME/Documents/ChatGPT/БД/БД_ЛР3"
docker start restaurant-lab-variant14
docker exec restaurant-lab-variant14 pg_isready -U student -d restaurant_lab
```

После `accepting connections`:

```bash
for lab_file in 01_analytics.sql 02_views.sql 03_materialized_view.sql 04_demo.sql; do
  docker exec -i restaurant-lab-variant14 psql -X -P pager=off \
    -v ON_ERROR_STOP=1 -U student -d restaurant_lab < "$lab_file" || break
done
```
