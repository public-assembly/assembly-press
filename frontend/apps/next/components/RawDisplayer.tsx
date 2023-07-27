// rome-ignore lint: Can't predict data type
export function RawDisplayer({ data }: { data: any }) {
  return (
    <div className="raw-displayer relative w-full overflow-x-scroll rounded-xl bg-gray-200 px-5 py-3 text-left">
      <code>
        <pre>{JSON.stringify(data, null, 2)}</pre>
      </code>
    </div>
  )
}
