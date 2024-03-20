using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace searcher
{
    public class IPSearch
    {
        private static readonly Lazy<IPSearch> lazy = new Lazy<IPSearch>(() => new IPSearch());
        public static IPSearch Instance { get { return lazy.Value; } }
        private IPSearch()
        {
            LoadDat();
            Watch();
        }

        private string datPath = "D:\\PycharmProjects\\ipdc-python-customer\\mmdb\\ipdatacloud_city.dat";
        private DateTime lastRead = DateTime.MinValue;

        private long[,] prefmap = new long[256, 2];
        private uint[] endArr;
        private string[] addrArr;
        private byte[] data;



        /// <summary>
        /// 初始化二进制  ipdatacloud.dat 数据
        /// </summary>

        private void LoadDat()
        {
            data = File.ReadAllBytes(datPath);

            for (int k = 0; k < 256; k++)
            {
                int i = k * 8 + 4;
                int prefix = k;
                long startIndex = ReadLittleEndian32(data[i], data[i + 1], data[i + 2], data[i + 3]);
                long endIndex = ReadLittleEndian32(data[i + 4], data[i + 5], data[i + 6], data[i + 7]);
                prefmap[k, 0] = startIndex; prefmap[k, 1] = endIndex;
            }

            uint RecordSize = ReadLittleEndian32(data[0], data[1], data[2], data[3]);
            endArr = new uint[RecordSize];
            addrArr = new string[RecordSize];
            for (int i = 0; i < RecordSize; i++)
            {
                long p = 2052 + (i * 9);
                uint endipnum = ReadLittleEndian32(data[p], data[1 + p], data[2 + p], data[3 + p]);

                int offset = data[4 + p] + ((data[5 + p]) << 8) + ((data[6 + p]) << 16) + ((data[7 + p]) << 24);
                int length = data[8 + p];

                endArr[i] = endipnum;
                addrArr[i] = Encoding.UTF8.GetString(data, offset, length);


            }



        }
        private void Watch()
        {
            FileInfo fi = new FileInfo(datPath);
            FileSystemWatcher watcher = new FileSystemWatcher(fi.DirectoryName)
            {
                IncludeSubdirectories = false,
                NotifyFilter = NotifyFilters.LastWrite,
                Filter = "ipdatacloud_city.dat",
            };

            watcher.Changed += (s, e) =>
            {

                var lastWriteTime = File.GetLastWriteTime(datPath);

                if (lastWriteTime > lastRead)
                {

                    Thread.Sleep(1000);

                    LoadDat();
                    lastRead = lastWriteTime;
                }
            };
            watcher.EnableRaisingEvents = true;
        }






        public string Find(string ip)
        {
            long pref;
            long val = IpToInt(ip, out pref);
            long low = prefmap[pref, 0], high = prefmap[pref, 1];
            long cur = low == high ? low : BinarySearch(low, high, val);

            if (cur == 100000000)
            {
                return "|";
            }

            return cur > -1 ? addrArr[cur] : "||||||||||";
        }




        private long BinarySearch(long low, long high, long k)
        {
            long M = -1, mid = 0;
            while (low <= high)
            {
                mid = (low + high) / 2;
                uint endipnum = endArr[mid];
                if (endipnum >= k)
                {
                    M = mid;
                    if (mid == 0)
                    {
                        break;
                    }
                    high = mid - 1;
                }
                else
                    low = mid + 1;
            }
            return M;
        }



        private long IpToInt(string ipString, out long prefix)
        {
            //高性能
            int end = ipString.Length;
            unsafe
            {
                fixed (char* name = ipString)
                {

                    int numberBase = 10;
                    char ch;
                    long[] parts = new long[4];
                    long currentValue = 0;
                    int dotCount = 0;
                    int current = 0;
                    for (; current < end; current++)
                    {
                        ch = name[current];
                        currentValue = 0;

                        numberBase = 10;
                        if (ch == '0')
                        {
                            numberBase = 8;
                            current++;

                            if (current < end)
                            {
                                ch = name[current];
                                if (ch == 'x' || ch == 'X')
                                {
                                    numberBase = 16;
                                    current++;
                                }
                            }
                        }

                        for (; current < end; current++)
                        {
                            ch = name[current];
                            int digitValue;

                            if ((numberBase == 10 || numberBase == 16) && '0' <= ch && ch <= '9')
                            {
                                digitValue = ch - '0';
                            }
                            else if (numberBase == 8 && '0' <= ch && ch <= '7')
                            {
                                digitValue = ch - '0';
                            }
                            else if (numberBase == 16 && 'a' <= ch && ch <= 'f')
                            {
                                digitValue = ch + 10 - 'a';
                            }
                            else if (numberBase == 16 && 'A' <= ch && ch <= 'F')
                            {
                                digitValue = ch + 10 - 'A';
                            }
                            else
                            {
                                break;
                            }

                            currentValue = (currentValue * numberBase) + digitValue;

                        }

                        if (current < end && name[current] == '.')
                        {
                            parts[dotCount] = currentValue;
                            dotCount++;
                            continue;
                        }
                        break;
                    }
                    parts[dotCount] = currentValue;
                    prefix = parts[0];
                    return (parts[0] << 24) | ((parts[1] & 0xff) << 16) | ((parts[2] & 0xff) << 8) | (parts[3] & 0xff);
                }
            }


        }


        private uint ReadBigEndian32(byte a, byte b, byte c, byte d)
        {
            return (uint)((a << 24) | (b << 16) | (c << 8) | d);
        }


        private uint ReadLittleEndian32(byte a, byte b, byte c, byte d)
        {
            return (uint)(a | (b << 8) | (c << 16) | (d << 24));
        }


    }
}
