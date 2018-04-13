defmodule Acme.BankOfHours do
  def run(configs, entries) do
    format_data(configs, entries)
    |> process_employees_hours(configs["period_start"], configs["today"])
  end

  def format_data(configs, entries) do
    Enum.map(entries, fn entrie ->
      pis_number = entrie["pis_number"]
      employee_configs = find_employee_configs(pis_number, configs)
      Map.put(employee_configs, "entries", entrie["entries"])
    end)
  end

  def find_employee_configs(pis_number, configs) do
    Enum.find(configs["employees"], fn employee -> employee["pis_number"] == pis_number end)
  end

  def process_employees_hours(employees, period_start, today) do
    Enum.map(employees, fn employee ->
      process_each_employee(employee, period_start, today)
    end)
  end

  def process_each_employee(employee, period_start, today) do
    order_entries_by_date(employee)
    |> process_entries(employee, period_start, today)
  end

  def order_entries_by_date(employee) do
    Enum.group_by(employee["entries"], fn entrie ->
      date = parse_entrie(entrie)
      Timex.to_date(date)
    end)
  end

  def process_entries(entries, employee, period_start, today) do
    Enum.map(entries, fn {date, entries} ->
      if Timex.compare(date, parse_date(period_start)) >= 0 &&
           Timex.compare(date, parse_date(today)) <= 0 do
        workload = get_workload(employee, get_week_day(Timex.weekday(date)))

        case entries do
          [start_work, start_interval, finish_interval, finish_work] ->
            rest_interval = diff_in_minutes(start_interval, finish_interval)
            work_time = diff_in_minutes(start_work, finish_work)

            workload_time = workload["workload_in_minutes"] || 0

            unrested_time =
              if work_time >= workload_time * 0.5 do
                unrested_time =
                  rest_interval - (workload["minimum_rest_interval_in_minutes"] || 0)

                (unrested_time >= 0 && unrested_time) || 0
              else
                0
              end

            work_time - rest_interval - workload_time + unrested_time

          [start_work, finish_work] ->
            diff_in_minutes(start_work, finish_work) - (workload["workload_in_minutes"] || 0) +
              (workload["minimum_rest_interval_in_minutes"] || 0)

          _ -> 0
        end
      end
    end)
    |> IO.inspect()
  end

  def diff_in_minutes(dt1, dt2) do
    Timex.diff(
      parse_entrie(dt1),
      parse_entrie(dt2),
      :minutes
    )
  end

  def get_week_day(week_day) do
    weekdays = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
    Enum.at(weekdays, week_day - 1)
  end

  def get_workload(employee, week_day) do
    Enum.find(employee["workload"], fn workload -> Enum.member?(workload["days"], week_day) end)
  end

  def parse_entrie(entrie) do
    {:ok, date} = Timex.parse(entrie, "{YYYY}-{0M}-{0D}T{h24}:{m}:{s}")
    date
  end

  def parse_date(date_str) do
    {:ok, date} = Timex.parse(date_str, "{YYYY}-{0M}-{0D}")
    date
  end
end
