defmodule Acme.BankOfHours do
  def run(configs, entries) do
    format_data(configs, entries)
    |> process_employees_hours(configs["period_start"], configs["today"])
    |> IO.inspect()
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
    |> format_employee(employee)
  end

  def order_entries_by_date(employee) do
    Enum.group_by(employee["entries"], fn entrie ->
      date = parse_entrie(entrie)
      Timex.to_date(date)
    end)
  end

  def format_employee(history, employee) do
    balance = Enum.reduce(history, 0, fn entrie, total -> total + entrie["balance"] end)

    %{
      "pis_number" => employee["pis_number"],
      "sumary" => %{"balance" => balance},
      "history" => history
    }
  end

  def process_entries(entries, employee, period_start, today) do
    Enum.map(entries, fn {date, entries} ->
      if Timex.compare(date, parse_date(period_start)) >= 0 &&
           Timex.compare(date, parse_date(today)) <= 0 do
        workload = get_workload(employee, get_week_day(Timex.weekday(date)))
        workload_time = workload["workload_in_minutes"] || 0
        minimum_rest_interval = workload["minimum_rest_interval_in_minutes"] || 0
        sorted_entries = Enum.sort(entries)

        worked_time = calc_work(sorted_entries)

        final_worked_time =
          worked_time - workload_time +
            calc_unrested_time(sorted_entries, worked_time, workload_time, minimum_rest_interval)

        %{"day" => date, "balance" => final_worked_time}
      end
    end)
  end

  def calc_work([start_work, finish_work | more_entries]),
    do: diff_in_minutes(start_work, finish_work) + calc_work(more_entries)

  def calc_work([_]), do: 0
  def calc_work([]), do: 0

  def calc_rest_interval([_, start_interval, finish_interval | more_entries]),
    do: diff_in_minutes(start_interval, finish_interval) + calc_rest_interval(more_entries)

  def calc_rest_interval([_, _]), do: 0
  def calc_rest_interval([_]), do: 0
  def calc_rest_interval([]), do: 0

  def calc_unrested_time(
        entries,
        worked_time,
        workload_time,
        minimum_rest_interval
      ) do
    rest_interval = calc_rest_interval(entries)

    if worked_time >= workload_time * 0.5 do
      unrested_time = minimum_rest_interval - rest_interval

      (unrested_time >= 0 && unrested_time) || 0
    else
      0
    end
  end

  def diff_in_minutes(dt1, dt2) do
    Timex.diff(
      parse_entrie(dt2),
      parse_entrie(dt1),
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
